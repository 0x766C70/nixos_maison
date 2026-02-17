{ config, pkgs, ... }:

{
  # fail2ban configuration for SSH and Caddy basic auth brute force prevention
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
          
          # SSH port to monitor (custom port 1337 from configuration.nix)
          port = "1337";
          
          # Filter to use for detecting failed SSH attempts
          filter = "sshd";
          
          # Time window to count failures (10 minutes)
          findtime = "10m";
        };
      };
      
      # Caddy basic auth jail
      caddy-auth = {
        settings = {
          # Enable the jail
          enabled = true;
          
          # HTTP and HTTPS ports
          port = "http,https";
          
          # Custom filter for Caddy basic auth failures
          filter = "caddy-auth";
          
          # Path to Caddy access log
          logpath = "/var/log/caddy/access.log";
          
          # Time window to count failures (10 minutes)
          findtime = "10m";
          
          # Maximum retries before ban (stricter than SSH: 3 vs 5 attempts)
          maxretry = 3;
          
          # Ban time for auth failures (2 hours)
          bantime = "2h";
        };
      };
    };
  };
  
  # Custom fail2ban filter for Caddy basic auth failures
  environment.etc."fail2ban/filter.d/caddy-auth.conf".text = ''
    # Fail2Ban filter for Caddy basic auth failures
    # 
    # Caddy logs authentication failures in JSON format with status code 401
    # This filter detects those failures and extracts the client IP address
    
    [Definition]
    
    # Match JSON logs with 401 Unauthorized status (failed basic auth)
    # Caddy JSON logs: "request":{"remote_ip":"x.x.x.x",...} followed by "status":401
    # Note: remote_ip appears before status in the log line
    failregex = "remote_ip":\s*"<ADDR>".*"status":\s*401
    
    # Ignore successful authentications (status 200, 301, 302, etc.)
    ignoreregex = "status":\s*[23]\d{2}
    
    # Date pattern for Caddy's Unix timestamp format in "ts" field
    # Caddy uses epoch time as floating point: "ts":1708197007.123456
    # %%s matches seconds, \. matches literal dot, %%f matches fractional seconds
    datepattern = {^LN-BEG}"ts":%%s\.%%f
  '';
}
