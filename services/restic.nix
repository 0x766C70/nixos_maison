{ config
, pkgs
, ...
}:
{
  # Restic - Encrypted backup with deduplication and versioning
  # Provides versioned backups with encryption and compression
  
  # Note: This configuration requires setting up a restic repository first
  # Run manually: restic init -r /path/to/repo or restic init -r s3:...
  
  services.restic.backups = {
    # Local encrypted backup of critical data
    nextcloud-local = {
      paths = [
        "/var/lib/nextcloud/data"
      ];
      
      # Repository location - encrypted LUKS disk
      repository = "/root/backup/restic/nextcloud";
      
      # Password file for repository encryption
      passwordFile = "${config.age.secrets.nextcloud.path}";
      
      # Backup schedule - daily at 3:30 AM
      timerConfig = {
        OnCalendar = "*-*-* 3:30:00";
        Persistent = true;
      };
      
      # Retention policy - keep snapshots for various time periods
      pruneOpts = [
        "--keep-daily 7"     # Last 7 days
        "--keep-weekly 4"    # Last 4 weeks
        "--keep-monthly 6"   # Last 6 months
        "--keep-yearly 2"    # Last 2 years
      ];
      
      # Initialize repository if it doesn't exist
      initialize = true;
      
      # Extra options
      extraBackupArgs = [
        "--exclude-caches"
        "--exclude=*.tmp"
        "--exclude=*/cache/*"
        "--exclude=*/thumbnails/*"
      ];
    };
    
    # Vaultwarden backup
    vaultwarden-local = {
      paths = [
        "/var/lib/vaultwarden"
      ];
      
      repository = "/root/backup/restic/vaultwarden";
      passwordFile = "${config.age.secrets.nextcloud.path}";
      
      timerConfig = {
        OnCalendar = "*-*-* 3:45:00";
        Persistent = true;
      };
      
      pruneOpts = [
        "--keep-daily 14"    # Keep 2 weeks of daily backups for passwords
        "--keep-weekly 8"
        "--keep-monthly 12"
      ];
      
      initialize = true;
    };
    
    # System configuration backup
    system-config = {
      paths = [
        "/etc/nixos"
        "/home/vlp/nixos_maison"
      ];
      
      repository = "/root/backup/restic/system";
      passwordFile = "${config.age.secrets.nextcloud.path}";
      
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
      
      pruneOpts = [
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
      
      initialize = true;
    };
  };
  
  # Notification service for restic backup failures
  systemd.services."restic-backup-failure@" = {
    description = "Send notification for failed restic backup %i";
    script = ''
      BACKUP_NAME="%i"
      MONITORING_EMAIL="monitoring@vlp.fdn.fr"
      
      echo "Subject: Restic Backup Failed - $BACKUP_NAME
From: maison@vlp.fdn.fr
To: $MONITORING_EMAIL

Restic Backup Failure Alert
============================

Backup: $BACKUP_NAME
Host: $(hostname)
Failed at: $(date)

Check logs for details:
  journalctl -u restic-backups-$BACKUP_NAME -n 50

-- 
Automated notification from NixOS Maison
      " | ${pkgs.msmtp}/bin/msmtp "$MONITORING_EMAIL"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
  
  # Add failure notifications to all restic backup services
  systemd.services."restic-backups-nextcloud-local".onFailure = [ "restic-backup-failure@nextcloud-local.service" ];
  systemd.services."restic-backups-vaultwarden-local".onFailure = [ "restic-backup-failure@vaultwarden-local.service" ];
  systemd.services."restic-backups-system-config".onFailure = [ "restic-backup-failure@system-config.service" ];
  
  # Create backup directories
  systemd.tmpfiles.rules = [
    "d /root/backup/restic 0700 root root - -"
    "d /root/backup/restic/nextcloud 0700 root root - -"
    "d /root/backup/restic/vaultwarden 0700 root root - -"
    "d /root/backup/restic/system 0700 root root - -"
  ];
  
  # Install restic for manual operations
  environment.systemPackages = [ pkgs.restic ];
}
