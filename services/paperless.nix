{ config
, pkgs
, ...
}:
{
  # Paperless-ngx - Document management system
  services.paperless = {
    enable = true;
    
    # Network settings
    address = "127.0.0.1";
    port = 28981;
    
    # Storage paths
    dataDir = "/var/lib/paperless";
    mediaDir = "/var/lib/paperless/media";
    consumptionDir = "/var/lib/paperless/consume";
    
    # Additional settings
    settings = {
      PAPERLESS_OCR_LANGUAGE = "eng+fra"; # English and French
      PAPERLESS_TIME_ZONE = "Europe/Paris";
      
      # Redis for better performance
      PAPERLESS_REDIS = "redis://localhost:6379";
      
      # Document processing
      PAPERLESS_CONSUMER_POLLING = 60; # Check for new docs every 60s
      PAPERLESS_OCR_MODE = "skip_noarchive"; # Skip OCR if already has text
      
      # Security
      PAPERLESS_ALLOWED_HOSTS = "paperless.vlp.fdn.fr,localhost,127.0.0.1";
      PAPERLESS_CORS_ALLOWED_HOSTS = "https://paperless.vlp.fdn.fr";
      
      # Email notifications (optional - configure via web UI)
      PAPERLESS_EMAIL_HOST = "localhost";
      
      # Enable task queue monitoring
      PAPERLESS_ENABLE_HTTP_REMOTE_USER = false;
    };
    
    # Admin password will be set on first run
    # Access web UI to configure
  };
  
  # Ensure Redis is available for Paperless
  services.redis.servers.paperless = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
  };
  
  # Create consumption directory for auto-import
  systemd.tmpfiles.rules = [
    "d /var/lib/paperless/consume 0755 paperless paperless - -"
    "d /var/lib/paperless/media 0755 paperless paperless - -"
  ];
}
