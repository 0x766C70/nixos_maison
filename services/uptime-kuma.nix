{ config
, pkgs
, ...
}:
{
  # Uptime Kuma - Self-hosted monitoring tool
  services.uptime-kuma = {
    enable = true;
    
    settings = {
      # Listen on localhost only, proxy via Caddy
      HOST = "127.0.0.1";
      PORT = "3001";
    };
  };
  
  # Security hardening for uptime-kuma
  systemd.services.uptime-kuma = {
    serviceConfig = {
      # Sandboxing
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      
      # State directory
      StateDirectory = "uptime-kuma";
      WorkingDirectory = "/var/lib/uptime-kuma";
      
      # Network
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      
      # Resources
      MemoryMax = "512M";
    };
  };
}
