{ ... }:

{
  # fail2ban configuration for SSH brute force prevention
  services.fail2ban = {
    enable = true;
    
    # Maximum number of login attempts before ban (global default)
    maxretry = 5;
    
    # How long an IP stays banned (global default: 1 hour)
    bantime = "1h";
    
    # Ban action to use (nftables-multiport works with networking.nftables.enable = true)
    banaction = "nftables-multiport";
    
    # Configure SSH jail
    jails = {
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
    };
  };
}
