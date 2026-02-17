{ config
, pkgs
, ...
}:
{
  # Immich - Modern photo and video management (Google Photos alternative)
  # High-performance, ML-powered photo organization
  
  # Note: Immich requires significant resources and is complex to set up in NixOS
  # This is a placeholder configuration. For production use, consider:
  # 1. Running Immich in a Docker container via Incus
  # 2. Using PhotoPrism (lighter weight alternative)
  # 3. Using Nextcloud Photos (already included)
  
  # Placeholder for future implementation
  # services.immich = {
  #   enable = false;
  #   # Full configuration would go here
  # };
  
  # For now, let's enable PhotoPrism as a lighter alternative
  services.photoprism = {
    enable = true;
    
    # Network settings
    address = "127.0.0.1";
    port = 2342;
    
    # Storage paths
    storagePath = "/var/lib/photoprism/storage";
    originalsPath = "/var/lib/photoprism/originals";
    importPath = "/var/lib/photoprism/import";
    
    # Settings
    settings = {
      PHOTOPRISM_ADMIN_USER = "admin";
      PHOTOPRISM_SITE_URL = "https://photos.vlp.fdn.fr";
      PHOTOPRISM_SITE_TITLE = "Family Photos";
      PHOTOPRISM_SITE_CAPTION = "Maison Photo Gallery";
      
      # Database (using SQLite for simplicity)
      PHOTOPRISM_DATABASE_DRIVER = "sqlite";
      
      # Features
      PHOTOPRISM_READONLY = false;
      PHOTOPRISM_EXPERIMENTAL = false;
      PHOTOPRISM_DISABLE_TLS = true; # TLS handled by Caddy
      
      # Upload and import
      PHOTOPRISM_UPLOAD_NSFW = true; # Allow all uploads
      PHOTOPRISM_DETECT_NSFW = false;
      
      # Face recognition
      PHOTOPRISM_DISABLE_FACES = false;
      
      # Resource limits
      PHOTOPRISM_WORKERS = 2;
      PHOTOPRISM_THUMB_SIZE = 2048;
    };
  };
  
  # Create necessary directories
  systemd.tmpfiles.rules = [
    "d /var/lib/photoprism 0755 photoprism photoprism - -"
    "d /var/lib/photoprism/storage 0755 photoprism photoprism - -"
    "d /var/lib/photoprism/originals 0755 photoprism photoprism - -"
    "d /var/lib/photoprism/import 0755 photoprism photoprism - -"
  ];
  
  # Optionally link to Nextcloud photos for indexing
  # systemd.services.photoprism.serviceConfig = {
  #   BindReadOnlyPaths = [ 
  #     "/var/lib/nextcloud/data/admin/files/Photos:/var/lib/photoprism/originals/nextcloud"
  #   ];
  # };
}
