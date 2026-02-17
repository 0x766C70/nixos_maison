{ config, pkgs, lib, ... }:

{
  # fail2ban: Intrusion prevention system that bans IPs after too many failed attempts
  # Protects SSH, Caddy web services, and Nextcloud from brute-force attacks
  
  services.fail2ban = {
    enable = true;
    
    # Maximum number of retries before ban
    maxretry = 5;
    
    # Ban duration in seconds (1 hour = 3600)
    bantime = "1h";
    
    # Time window for counting retries (10 minutes)
    findtime = "10m";
    
    # Ban action with email notifications
    # Uses msmtp configured in services/msmtp.nix to send alerts
    banaction = "iptables-multiport";
    banaction-allports = "iptables-allports";
    
    # Ignore localhost and local network
    ignoreIP = [
      "127.0.0.1/8"
      "::1"
      "192.168.1.0/24"  # Local network
    ];
    
    # Jail configurations for different services
    jails = {
      # SSH protection on custom port 1337
      # Prevents brute-force attacks on SSH service
      sshd = ''
        enabled = true
        port = 1337
        filter = sshd
        maxretry = 3
        findtime = 5m
        bantime = 2h
        logpath = /var/log/auth.log
        action = %(action_mwl)s
      '';
      
      # Caddy/HTTP basic auth protection
      # Protects services with basic authentication (dl.vlp.fdn.fr, laptop.vlp.fdn.fr)
      caddy-auth = ''
        enabled = true
        port = http,https
        filter = caddy-auth
        maxretry = 5
        findtime = 10m
        bantime = 1h
        logpath = /var/log/caddy/access*.log
        action = %(action_mwl)s
      '';
      
      # Nextcloud brute-force protection
      # Prevents credential stuffing attacks on Nextcloud login
      nextcloud = ''
        enabled = true
        port = http,https
        filter = nextcloud
        maxretry = 3
        findtime = 10m
        bantime = 1h
        logpath = /var/lib/nextcloud/data/nextcloud.log
        action = %(action_mwl)s
      '';
      
      # Generic HTTP authentication failures
      # Catches any HTTP auth failures not covered by specific jails
      http-auth = ''
        enabled = true
        port = http,https
        filter = apache-auth
        maxretry = 5
        findtime = 10m
        bantime = 1h
        logpath = /var/log/caddy/access*.log
        action = %(action_mwl)s
      '';
    };
  };
  
  # Create custom filter for Caddy authentication failures
  # Matches 401 Unauthorized responses in Caddy logs
  environment.etc."fail2ban/filter.d/caddy-auth.conf".text = ''
    [Definition]
    failregex = ^.*"GET .*" 401 .*$
                ^.*"POST .*" 401 .*$
    ignoreregex =
  '';
  
  # Create custom filter for Nextcloud brute-force attempts
  # Matches failed login attempts in Nextcloud logs
  environment.etc."fail2ban/filter.d/nextcloud.conf".text = ''
    [Definition]
    failregex = .*Login failed: '.*' \(Remote IP: '<HOST>'\).*$
                .*\"remoteAddr\":\"<HOST>\".*\"message\":\"Login failed:.*$
    ignoreregex =
  '';
  
  # Configure email notifications using msmtp
  # Sends alerts when IPs are banned or unbanned
  environment.etc."fail2ban/action.d/mail-mwl.local".text = ''
    [Definition]
    actionstart = echo "Fail2ban <name> jail has been started on $(hostname)" | ${pkgs.msmtp}/bin/msmtp monitoring@vlp.fdn.fr
    actionstop = echo "Fail2ban <name> jail has been stopped on $(hostname)" | ${pkgs.msmtp}/bin/msmtp monitoring@vlp.fdn.fr
    actionban = echo "Fail2ban <name>: banned <ip> from $(hostname) after <failures> attempts" | ${pkgs.msmtp}/bin/msmtp monitoring@vlp.fdn.fr
    actionunban = echo "Fail2ban <name>: unbanned <ip> from $(hostname)" | ${pkgs.msmtp}/bin/msmtp monitoring@vlp.fdn.fr
  '';
  
  # Ensure fail2ban package is available for CLI management
  # Commands: fail2ban-client status, fail2ban-client status <jail>
  environment.systemPackages = with pkgs; [
    fail2ban
  ];
  
  # Ensure required log directories exist
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];
}
