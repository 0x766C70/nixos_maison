{ config
, pkgs
, ...
}:
{
  # fail2ban for intrusion prevention
  services.fail2ban = {
    enable = true;
    maxretry = 5; # Ban after 5 failed attempts
    ignoreIP = [
      "127.0.0.0/8"
      "192.168.0.0/16" # Local network
      "100.64.0.0/10"  # Tailscale/Headscale network
    ];
    
    bantime = "1h"; # Ban for 1 hour
    bantime-increment = {
      enable = true; # Increase ban time for repeat offenders
      maxtime = "168h"; # Max ban time of 1 week
      factor = "2"; # Double the ban time each offense
    };

    jails = {
      # SSH protection (custom port 1337)
      sshd = {
        enabled = true;
        filter = "sshd";
        port = "1337";
        maxretry = 3;
      };
      
      # Caddy reverse proxy protection
      caddy-auth = {
        enabled = true;
        filter = "caddy-auth";
        port = "80,443";
        maxretry = 5;
        logpath = "/var/log/caddy/*.log";
      };
    };
  };

  # Custom filter for Caddy basic auth failures
  environment.etc."fail2ban/filter.d/caddy-auth.conf".text = ''
    [Definition]
    failregex = ^.*\[ERROR\].*http\.authentication\.basic.*wrong credentials.*"remote_ip":"<HOST>".*$
                ^.*\[ERROR\].*http\.authentication\.basic.*user not found.*"remote_ip":"<HOST>".*$
    ignoreregex =
    datepattern = {^LN-BEG}"ts":(%%Y-%%m-%%dT%%H:%%M:%%S)
  '';

  # Ensure Caddy logs in JSON format for fail2ban parsing
  services.caddy.logFormat = ''
    output file /var/log/caddy/access.log {
      roll_size 100mb
      roll_keep 5
    }
    format json
  '';
}
