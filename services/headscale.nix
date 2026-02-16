{ config
, pkgs
, ...
}:
{
  # Headscale - self-hosted Tailscale control server
  # This is like Jarvis for your network—except it won't develop sentience
  services.headscale = {
    enable = true;
    address = "127.0.0.1"; # Only listen locally, Caddy will handle external access
    port = 8085;
    
    settings = {
      # Server URL - this is where clients will connect
      server_url = "https://hs.vlp.fdn.fr";
      
      # DNS configuration - because naming things is important
      dns_config = {
        override_local_dns = true;
        base_domain = "vlp.fdn.fr";
        magic_dns = true;
        domains = [ "hs.vlp.fdn.fr" ];
        nameservers = [ "1.1.1.1" "1.0.0.1" ]; # Cloudflare DNS
      };
      
      # IP prefixes for the VPN network
      # Using standard Tailscale ranges
      ip_prefixes = [
        "100.64.0.0/10"      # IPv4 range
        "fd7a:115c:a1e0::/48" # IPv6 range
      ];
      
      # Database settings - SQLite is used by default
      # Simple, reliable, and doesn't require a separate DB server
      database.type = "sqlite";
      
      # Log level for troubleshooting
      log.level = "info";
    };
  };
}
