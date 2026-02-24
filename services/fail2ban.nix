{ config, pkgs, ... }:

{
  # fail2ban configuration for SSH, Caddy basic auth, and Nextcloud brute force prevention
  services.fail2ban = {
    enable = true;
    
    # Maximum number of login attempts before ban (global default)
    maxretry = 5;
    
    # How long an IP stays banned (global default: 1 hour)
    bantime = "1h";
    
    # Ban action to use (nftables-multiport works with networking.nftables.enable = true)
    banaction = "nftables-multiport";
    
    # Configure jails
    jails = {
      # SSH jail
      sshd = {
        settings = {
          # Enable the jail
          enabled = true;
          
          # Use systemd backend (NixOS uses systemd journal for SSH logs, not /var/log/auth.log)
          backend = "systemd";
          
          # SSH ports to monitor (custom ports from configuration.nix)
          port = "1337";
          
          # Filter to use for detecting failed SSH attempts
          filter = "sshd";
          
          # Time window to count failures (10 minutes)
          findtime = "10m";
        };
      };
      
      # Caddy basic auth jail for dl.vlp.fdn.fr
      dl-caddy-auth = {
        settings = {
          # Enable the jail
          enabled = true;
          
          # HTTP and HTTPS ports
          port = "http,https";
          
          # Custom filter for Caddy basic auth failures
          filter = "dl-caddy-auth";
          
          # Path to Caddy access log for dl.vlp.fdn.fr
          logpath = "/var/log/caddy/access-dl.vlp.fdn.fr.log";
          
          # Time window to count failures (10 minutes)
          findtime = "10m";
          
          # Maximum retries before ban (stricter than SSH: 3 vs 5 attempts)
          maxretry = 3;
          
          # Ban time for auth failures (2 hours)
          bantime = "2h";
        };
      };
      
      # Caddy basic auth jail for laptop.vlp.fdn.fr
      laptop-caddy-auth = {
        settings = {
          # Enable the jail
          enabled = true;
          
          # HTTP and HTTPS ports
          port = "http,https";
          
          # Custom filter for Caddy basic auth failures
          filter = "laptop-caddy-auth";
          
          # Path to Caddy access log for laptop.vlp.fdn.fr
          logpath = "/var/log/caddy/access-laptop.vlp.fdn.fr.log";
          
          # Time window to count failures (10 minutes)
          findtime = "10m";
          
          # Maximum retries before ban (stricter than SSH: 3 vs 5 attempts)
          maxretry = 3;
          
          # Ban time for auth failures (2 hours)
          bantime = "2h";
        };
      };
      
      # Nextcloud jail for login brute force protection
      nextcloud = {
        settings = {
          # Enable the jail
          enabled = true;
          
          # HTTP and HTTPS ports (Nextcloud is accessed via reverse proxy)
          port = "http,https";
          
          # Custom filter for Nextcloud login failures
          filter = "nextcloud";
          
          # Path to Nextcloud log file
          logpath = "/var/lib/nextcloud/data/nextcloud.log";
          
          # Time window to count failures (10 minutes)
          findtime = "10m";
          
          # Maximum retries before ban (5 attempts)
          maxretry = 5;
          
          # Ban time for login failures (2 hours, same as Caddy)
          bantime = "2h";
        };
      };
    };
  };
  
  # Custom fail2ban filter for Caddy basic auth failures
  environment.etc."fail2ban/filter.d/dl-caddy-auth.conf".text = ''
    [Definition]
    failregex = ^.*"remote_ip":\s*"<ADDR>".*"status":\s*(401|403).*$
  '';
  
  # Custom fail2ban filter for Caddy basic auth failures
  environment.etc."fail2ban/filter.d/laptop-caddy-auth.conf".text = ''
    [Definition]
    failregex = "request":\s*\{.*?"remote_ip":\s*"<ADDR>".*"status":\s*401
    ignoreregex = "status":\s*[23]\d{2}
    datepattern = {^LN-BEG}"ts":%%s\.%%f
  '';

  # Custom fail2ban filter for Nextcloud login failures
  environment.etc."fail2ban/filter.d/nextcloud.conf".text = ''
    [Definition]
    _groupsre = .*?
    failregex = ^\{%(_groupsre)s"remoteAddr"\s*:\s*"<ADDR>"%(_groupsre)s"message"\s*:\s*"Login failed:
                ^\{%(_groupsre)s"remoteAddr"\s*:\s*"<ADDR>"%(_groupsre)s"message"\s*:\s*"Trusted domain error\.
                ^\{%(_groupsre)s"remoteAddr"\s*:\s*"<ADDR>"%(_groupsre)s"message"\s*:\s*"Two-factor challenge failed:
    ignoreregex = 
    datepattern = "time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
  '';
}
