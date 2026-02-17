{ config
, pkgs
, ...
}:
{
  # FreshRSS - RSS feed aggregator for news and blogs
  services.freshrss = {
    enable = true;
    
    # Network configuration
    baseUrl = "https://rss.vlp.fdn.fr";
    
    # Database (SQLite for simplicity)
    database = {
      type = "sqlite";
      path = "/var/lib/freshrss/db.sqlite";
    };
    
    # Virtual host configuration
    virtualHost = "localhost";
    
    # Admin user (set password on first login)
    defaultUser = "admin";
  };
  
  # Use Nginx provided by FreshRSS module, but bind to localhost only
  services.nginx.virtualHosts."localhost" = {
    listen = [{ addr = "127.0.0.1"; port = 8084; }];
  };
  
  # Ensure data directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/freshrss 0750 freshrss nginx - -"
  ];
}
