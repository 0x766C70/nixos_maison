{ config
, pkgs
, ...
}:
{
  # AdGuard Home for network-wide ad blocking and parental controls
  services.adguardhome = {
    enable = true;
    
    # Bind to local network interface
    host = "0.0.0.0";
    port = 3000; # Web interface port
    
    # Settings will be configured via web UI on first run
    # Access at http://192.168.1.42:3000 for initial setup
    settings = {
      # DNS settings
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        
        # Upstream DNS servers (using Cloudflare and Quad9)
        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.quad9.net/dns-query"
        ];
        
        # Bootstrap DNS for resolving DoH/DoT hostnames
        bootstrap_dns = [
          "1.1.1.1"
          "9.9.9.9"
        ];
        
        # Enable query logging for troubleshooting
        querylog_enabled = true;
        querylog_interval = "2160h"; # 90 days
        
        # Enable stats
        statistics_interval = 30; # days
        
        # Enable safe browsing and parental control
        safebrowsing_enabled = true;
        parental_enabled = false; # Enable via web UI if needed
        
        # Resolve local domains via system DNS
        local_ptr_upstreams = [ "192.168.1.1" ];
      };
      
      # DHCP server disabled (assuming router handles DHCP)
      dhcp = {
        enabled = false;
      };
      
      # Filters
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://adaway.org/hosts.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
      ];
    };
  };

  # Open firewall ports for AdGuard Home
  networking.firewall.allowedTCPPorts = [ 3000 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
  
  # Ensure AdGuard directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/AdGuardHome 0750 adguardhome adguardhome - -"
  ];
}
