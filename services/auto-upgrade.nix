{ config
, pkgs
, lib
, ...
}:
{
  # Automatic system updates for security patches
  system.autoUpgrade = {
    enable = true;
    flake = "/home/vlp/nixos_maison#maison"; # Update to your actual flake location
    flags = [
      "--update-input" "nixpkgs"
      "--commit-lock-file"
    ];
    dates = "weekly"; # Run every Sunday at 3 AM
    allowReboot = true;
    rebootWindow = {
      lower = "03:00";
      upper = "05:00";
    };
    
    # Send notification on upgrade completion/failure
    operation = "switch"; # Can be "boot" or "switch"
  };

  # Notification service for upgrade status
  systemd.services."auto-upgrade-notification" = {
    description = "Send notification after auto-upgrade";
    after = [ "nixos-upgrade.service" ];
    wants = [ "nixos-upgrade.service" ];
    
    script = ''
      # Determine if the upgrade succeeded or failed
      if systemctl is-failed nixos-upgrade.service > /dev/null 2>&1; then
        STATUS="FAILED"
        SUBJECT="System Auto-Upgrade Failed on Maison"
      else
        STATUS="SUCCESS"
        SUBJECT="System Auto-Upgrade Completed on Maison"
      fi
      
      # Get upgrade logs
      LOGS=$(${pkgs.systemd}/bin/journalctl -u nixos-upgrade.service -n 50 --no-pager)
      
      echo "Subject: $SUBJECT
From: maison@vlp.fdn.fr
To: monitoring@vlp.fdn.fr

Auto-Upgrade Status Report
===========================

Status: $STATUS
Host: $(hostname)
Completed at: $(date)

Recent Logs:
$LOGS

-- 
Automated notification from NixOS Maison
      " | ${pkgs.msmtp}/bin/msmtp monitoring@vlp.fdn.fr
    '';
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # Ensure auto-upgrade runs notification on completion
  systemd.services.nixos-upgrade = {
    onSuccess = [ "auto-upgrade-notification.service" ];
    onFailure = [ "auto-upgrade-notification.service" ];
    
    serviceConfig = {
      # Log to journal for debugging
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # Automatic garbage collection to keep system clean
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  
  # Optimize nix store weekly
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
