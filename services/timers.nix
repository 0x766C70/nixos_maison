{ config, pkgs, ... }:
{
  # State directory for storing the last known IP
  systemd.tmpfiles.rules = [
    "d /var/lib/my_ip 0755 root root - -"
  ];

  # ===========================
  # Backup Failure Notification
  # ===========================

  # Service that sends email notification when backup fails
  systemd.services."backup-failure-notification@" = {
    description = "Send email notification on backup failure for %i";
    script = ''
            MONITORING_EMAIL="monitoring@vlp.fdn.fr"
      
            echo "Sending backup failure notification for $FAILED_SERVICE at $(date)"
      
            # Send email notification - don't use set -e to ensure we always attempt to send
            if echo "Subject: Backup Failed on Maison - $FAILED_SERVICE
      From: maison@vlp.fdn.fr
      To: $MONITORING_EMAIL

      Backup Failure Alert
      ====================

      Service: $FAILED_SERVICE
      Host: $(hostname)
      Failed at: $(date)

      A backup job has failed. Check system logs for details:
        journalctl -u $FAILED_SERVICE -n 50

      -- 
      Automated notification from NixOS Maison
      " | ${pkgs.msmtp}/bin/msmtp "$MONITORING_EMAIL" 2>&1; then
              echo "Failure notification sent successfully to $MONITORING_EMAIL"
            else
              echo "ERROR: Failed to send email notification to $MONITORING_EMAIL"
              exit 1
            fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Environment = "FAILED_SERVICE=%i";
    };
  };

  # ===========================
  # Backup Timers
  # ===========================

  # Daily Nextcloud backup at 4 AM
  systemd.timers."backup_nc" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 4:00:00";
      Persistent = true; # Run on boot if missed
      Unit = "backup_nc.service";
    };
  };

  systemd.services."backup_nc" = {
    description = "Backup Nextcloud data to local directory";
    script = ''
      set -e  # Exit immediately on error
      
      echo "Starting Nextcloud backup at $(date)"
      
      # Verify that /home/vlp/backup is mounted before proceeding
      if ! ${pkgs.util-linux}/bin/mountpoint -q /home/vlp/backup; then
        echo "ERROR: /home/vlp/backup is not mounted! Backup aborted to prevent writing to local storage."
        echo "Check that the luks-sdb1-unlock service succeeded: systemctl status luks-sdb1-unlock.service"
        exit 1
      fi
      
      echo "/home/vlp/backup is properly mounted - proceeding with backup"
      
      # Run rsync backup
      ${pkgs.rsync}/bin/rsync -a --delete \
        /var/lib/nextcloud/data/ \
        /home/vlp/backup/nextcloud/
      
      echo "Nextcloud backup completed successfully at $(date)"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "vlp";
    };
    # Send email notification on failure
    onFailure = [ "backup-failure-notification@%n.service" ];
  };

  # Remote backup at 5 AM
  systemd.timers."remote_backup_nc" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 5:00:00";
      Persistent = true; # Run on boot if missed
      Unit = "remote_backup_nc.service";
    };
  };

  systemd.services."remote_backup_nc" = {
    description = "Remote backup of Nextcloud data via reverse SSH tunnel";
    path = [ pkgs.openssh pkgs.gnupg ];
    environment = {
      # Set DEBUG=1 to enable verbose output for troubleshooting:
      #   systemctl set-environment DEBUG=1
      #   systemctl start remote_backup_nc.service
      #   journalctl -u remote_backup_nc.service -f
      # Reset afterwards with: systemctl unset-environment DEBUG
      DEBUG = "0";
    };
    script = ''
      set -e  # Exit immediately on error

      # Debug mode: print every command before executing and show diagnostics.
      if [ "''${DEBUG:-0}" = "1" ]; then
        set -x
      fi

      # Export the GPG agent SSH socket so that SSH can authenticate using the
      # YubiKey-backed key.  In interactive sessions this is done by .bashrc, but
      # systemd services do not source .bashrc, so we must set it here explicitly.
      export SSH_AUTH_SOCK=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)
      ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent

      # In debug mode, dump agent and key info so we can confirm auth is wired up.
      if [ "''${DEBUG:-0}" = "1" ]; then
        echo "DEBUG: SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
        echo "DEBUG: GPG agent socket:"
        ls -la "$SSH_AUTH_SOCK" 2>&1 || echo "DEBUG: socket file not found"
        echo "DEBUG: Keys loaded in SSH agent:"
        ${pkgs.openssh}/bin/ssh-add -l 2>&1 || true
      fi

      echo "Starting remote Nextcloud backup at $(date)"
      
      # azul is inside the tailnet and cannot be reached directly from maison
      # (headscale control servers must not join the tailnet).
      # Instead, azul maintains a persistent reverse SSH tunnel to maison:
      #
      #   On azul (run once, e.g. via a systemd service):
      #     autossh -M 0 -N -R 127.0.0.1:2222:localhost:22 \
      #       -i /home/vlp/.ssh/id_ed25519_tunnel \
      #       -p 1337 vlp@hs.vlp.fdn.fr
      #
      # This exposes azul:22 on maison's localhost:2222.
      
      # Verify the reverse tunnel is active before attempting the backup.
      # Use ssh in BatchMode so it exits immediately without prompting:
      # exit code 0 = tunnel up + auth works; non-zero = tunnel down or no key.
      # In debug mode pass -v so the full SSH handshake/auth trace appears in the
      # journal; otherwise suppress stderr noise from a plain "tunnel not up" case.
      # Arrays avoid empty-string argument issues when the flag is not needed.
      SSH_DEBUG_FLAGS=()
      RSYNC_DEBUG_FLAGS=()
      SSH_TRANSPORT_VERBOSE=""
      if [ "''${DEBUG:-0}" = "1" ]; then
        SSH_DEBUG_FLAGS=(-v)
        RSYNC_DEBUG_FLAGS=(-v)
        SSH_TRANSPORT_VERBOSE=" -v"
      fi

      if ! ${pkgs.openssh}/bin/ssh \
           "''${SSH_DEBUG_FLAGS[@]}" \
           -p 2222 \
           -o ConnectTimeout=5 \
           -o BatchMode=yes \
           -o StrictHostKeyChecking=accept-new \
           vlp@127.0.0.1 exit 2>&1; then
        echo "ERROR: Reverse SSH tunnel from azul is not active on localhost:2222"
        echo "Ensure azul is running: autossh -M 0 -N -R 127.0.0.1:2222:localhost:22 -p 1337 vlp@hs.vlp.fdn.fr"
        exit 1
      fi
      
      echo "Reverse tunnel to azul is active - proceeding with backup"
      
      # Run rsync through the reverse tunnel (azul's SSH is on localhost:2222).
      # StrictHostKeyChecking=accept-new is acceptable here: the connection is
      # to 127.0.0.1 over the already-authenticated reverse tunnel, so MITM
      # is not a practical concern.
      # In debug mode, add -v to rsync and to the inner SSH transport.
      ${pkgs.rsync}/bin/rsync -a --delete "''${RSYNC_DEBUG_FLAGS[@]}" \
        -e "${pkgs.openssh}/bin/ssh -p 2222 -o StrictHostKeyChecking=accept-new$SSH_TRANSPORT_VERBOSE" \
        /home/vlp/backup/nextcloud/ \
        vlp@127.0.0.1:/home/vlp/backup_maison/nextcloud/
      
      echo "Remote Nextcloud backup completed successfully at $(date)"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "vlp";
    };
    # Send email notification on failure
    onFailure = [ "backup-failure-notification@%n.service" ];
  };

  # ===========================
  # IP Address Monitor
  # ===========================

  # Check IP every 2 hours instead of once a day for more responsiveness
  systemd.timers."my_ip" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* */2:00:00"; # Every 2 hours
      Persistent = true;
      Unit = "my_ip.service";
    };
  };

  systemd.services."my_ip" = {
    description = "Monitor public IP and send email on change";
    script = ''
            set -e  # Exit immediately on error
      
            STATE_FILE="/var/lib/my_ip/last_ip"
      
            echo "Checking public IP at $(date)"
      
            # Fetch current public IP
            CURRENT_IP=$(${pkgs.curl}/bin/curl -s https://api.ipify.org?format=json | ${pkgs.jq}/bin/jq -r '.ip')
      
            if [ -z "$CURRENT_IP" ]; then
              echo "ERROR: Failed to fetch public IP"
              exit 1
            fi
      
            echo "Current IP: $CURRENT_IP"
      
            # Check if we have a previous IP
            if [ -f "$STATE_FILE" ]; then
              LAST_IP=$(cat "$STATE_FILE")
              echo "Last known IP: $LAST_IP"
        
              # Only send email if IP has changed
              if [ "$CURRENT_IP" != "$LAST_IP" ]; then
                echo "IP has changed from $LAST_IP to $CURRENT_IP - sending notification"
          
                # Send email notification
                echo "Subject: Maison IP Changed
      From: maison@vlp.fdn.fr
      To: thomas@criscione.fr

      Maison IP Address Changed
      ==========================

      Previous IP: $LAST_IP
      New IP: $CURRENT_IP
      Changed at: $(date)
      " | ${pkgs.msmtp}/bin/msmtp thomas@criscione.fr
          
                # Update state file
                echo "$CURRENT_IP" > "$STATE_FILE"
                echo "Email sent and state file updated"
              else
                echo "IP unchanged - no notification sent"
              fi
            else
              # First run - save IP and send initial notification
              echo "First run - saving initial IP and sending notification"
              echo "$CURRENT_IP" > "$STATE_FILE"
        
              echo "Subject: Maison IP Initial Check
      From: maison@vlp.fdn.fr
      To: thomas@criscione.fr

      Maison IP Address Monitoring Started
      =====================================

      Initial IP: $CURRENT_IP
      Started at: $(date)
      " | ${pkgs.msmtp}/bin/msmtp thomas@criscione.fr
        
              echo "Initial IP saved and notification sent"
            fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };


  # ===========================
  # Transmission prune finished torrents (30d)
  # ===========================

  # Daily prune of finished Transmission torrents older than 30 days, at 6 AM
  systemd.timers."transmission-prune-finished-30d" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 6:00:00";
      Persistent = true; # Run on boot if missed
      Unit = "transmission-prune-finished-30d.service";
    };
  };

  systemd.services."transmission-prune-finished-30d" = {
    description = "Prune finished Transmission torrents older than 30 days";
    path = [ pkgs.transmission_4 pkgs.gawk pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.findutils ];
    script = ''
      ${pkgs.bash}/bin/bash ${../bin/transmission-prune-finished-30d.sh}
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # ===========================
  # NC preview generator
  # ===========================

  systemd.timers."nextcloud-preview-gen" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      Unit = "nextcloud-preview-gen.service";
    };
  };

  systemd.services."nextcloud-preview-gen" = {
    description = "Generate Nextcloud previews";
    script = ''
      ${config.services.nextcloud.occ}/bin/nextcloud-occ preview:pre-generate
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
    };
  };
}
