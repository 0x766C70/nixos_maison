{ config
, pkgs
, ...
}:
{
  # Vaultwarden - Bitwarden-compatible password manager
  # Lightweight Rust implementation, perfect for family password sharing
  services.vaultwarden = {
    enable = true;
    
    # Configuration
    config = {
      # Network settings
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      
      # Domain configuration
      DOMAIN = "https://vault.vlp.fdn.fr";
      
      # Signups and invitations
      SIGNUPS_ALLOWED = false; # Disable public signups
      INVITATIONS_ALLOWED = true; # Allow admin to invite family
      
      # Email configuration (for invites and password resets)
      # Configure these after initial setup via web UI
      # SMTP_HOST = "localhost";
      # SMTP_FROM = "vault@vlp.fdn.fr";
      # SMTP_PORT = 587;
      
      # Security settings
      SHOW_PASSWORD_HINT = false;
      PASSWORD_ITERATIONS = 350000;
      
      # Enable web vault
      WEB_VAULT_ENABLED = true;
      
      # Logging
      LOG_LEVEL = "info";
      
      # Disable admin token requirement for first login
      # Set a strong admin token via env var after initial setup
    };
    
    # Backup directory
    backupDir = "/var/lib/vaultwarden/backups";
  };
  
  # Security hardening
  systemd.services.vaultwarden = {
    serviceConfig = {
      # Sandboxing
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      ReadWritePaths = [ "/var/lib/vaultwarden" ];
      
      # Network security
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      
      # Resource limits
      MemoryMax = "256M";
    };
  };
  
  # Automatic database backups (daily at 2 AM)
  systemd.timers."vaultwarden-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 2:00:00";
      Persistent = true;
    };
  };
  
  systemd.services."vaultwarden-backup" = {
    description = "Backup Vaultwarden database";
    script = ''
      set -e
      
      BACKUP_DIR="/var/lib/vaultwarden/backups"
      DB_FILE="/var/lib/vaultwarden/db.sqlite3"
      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      
      echo "Backing up Vaultwarden database at $(date)"
      
      # Create backup directory if it doesn't exist
      mkdir -p "$BACKUP_DIR"
      
      # Backup database with timestamp
      ${pkgs.sqlite}/bin/sqlite3 "$DB_FILE" ".backup '$BACKUP_DIR/db_$TIMESTAMP.sqlite3'"
      
      # Keep only last 30 backups
      cd "$BACKUP_DIR"
      ls -t db_*.sqlite3 | tail -n +31 | xargs -r rm
      
      echo "Vaultwarden backup completed successfully"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "vaultwarden";
    };
    onFailure = [ "backup-failure-notification@%n.service" ];
  };
  
  # Ensure backup directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden/backups 0750 vaultwarden vaultwarden - -"
  ];
}
