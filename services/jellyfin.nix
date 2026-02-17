{ config
, pkgs
, ...
}:
{
  # Jellyfin media server - modern alternative to DLNA
  services.jellyfin = {
    enable = true;
    openFirewall = true; # Opens port 8096 for web UI
    
    # Additional configuration
    user = "jellyfin";
    group = "jellyfin";
  };

  # Add jellyfin user to groups for media access
  users.users.jellyfin = {
    extraGroups = [ "video" "render" "mlc" "users" ];
  };

  # Hardware acceleration for transcoding (if Intel GPU available)
  # Uncomment if you have Intel integrated graphics
  # hardware.opengl = {
  #   enable = true;
  #   extraPackages = with pkgs; [
  #     intel-media-driver
  #     vaapiIntel
  #     vaapiVdpau
  #     libvdpau-va-gl
  #   ];
  # };

  # Ensure media directories are accessible
  systemd.services.jellyfin = {
    serviceConfig = {
      # Allow Jellyfin to access NFS mounts
      ReadWritePaths = [
        "/var/lib/jellyfin"
        "/mnt/movies"
        "/mnt/tvshows"
        "/mnt/animations"
        "/mnt/audio"
        "/mnt/docu"
        "/mnt/downloads"
      ];
      
      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      
      # Resource limits
      MemoryMax = "4G"; # Adjust based on your system
    };
  };
}
