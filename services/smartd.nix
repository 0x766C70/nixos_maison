{ config
, pkgs
, ...
}:
{
  # S.M.A.R.T monitoring for disk health
  services.smartd = {
    enable = true;
    
    # Monitor all devices
    autodetect = true;
    
    # Notification settings
    notifications = {
      mail = {
        enable = true;
        sender = "maison@vlp.fdn.fr";
        recipient = "monitoring@vlp.fdn.fr";
        mailer = "${pkgs.msmtp}/bin/msmtp";
      };
      
      # Test notification (sends email on startup)
      test = true;
    };
    
    # Default monitoring for all devices
    defaults.monitored = ''
      -a                     # Monitor all attributes
      -o on                  # Enable automatic offline data collection
      -S on                  # Enable automatic attribute autosave
      -s (S/../.././02|L/../../6/03)  # Short self-test daily at 2am, long test weekly on Sat at 3am
      -H                     # Check SMART health status
      -l error              # Report errors
      -l selftest           # Report self-test errors
      -f                     # Check for failure of any usage attribute
      -m monitoring@vlp.fdn.fr  # Email address for alerts
      -M exec ${pkgs.msmtp}/bin/msmtp  # Use msmtp for email
    '';
  };
  
  # Ensure systemd service has access to msmtp config
  systemd.services.smartd = {
    serviceConfig = {
      Environment = "MSMTP_CONFIG=${config.age.secrets.mail.path}";
    };
  };
}
