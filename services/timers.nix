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
      set -e
      
      # Get the failed service name from the instance parameter
      FAILED_SERVICE="%i"
      
      echo "Sending backup failure notification for $FAILED_SERVICE at $(date)"
      
      # Send email notification
      echo "Subject: Backup Failed on Maison - $FAILED_SERVICE
From: maison@vlp.fdn.fr
To: monitoring@vlp.fdn.fr

Backup Failure Alert
====================

Service: $FAILED_SERVICE
Host: $(hostname)
Failed at: $(date)

A backup job has failed. Check system logs for details:
  journalctl -u $FAILED_SERVICE -n 50

-- 
Automated notification from NixOS Maison
" | ${pkgs.msmtp}/bin/msmtp monitoring@vlp.fdn.fr
      
      echo "Failure notification sent successfully"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
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
      
      # Run rsync backup
      ${pkgs.rsync}/bin/rsync -a --delete \
        /var/lib/nextcloud/data/ \
        /root/backup/nextcloud/
      
      echo "Nextcloud backup completed successfully at $(date)"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
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
    description = "Remote backup of Nextcloud data";
    path = [ pkgs.openssh ];
    script = ''
      set -e  # Exit immediately on error
      
      echo "Starting remote Nextcloud backup at $(date)"
      
      # Run rsync backup to remote server
      ${pkgs.rsync}/bin/rsync -a --delete \
        /root/backup/nextcloud/ \
        vlp@azul.vlp.fdn.fr:/home/vlp/backup_maison/nextcloud/
      
      echo "Remote Nextcloud backup completed successfully at $(date)"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
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
