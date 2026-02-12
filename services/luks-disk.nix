{ config, pkgs, lib, ... }:

{
  # Create mount point for the LUKS encrypted disk
  systemd.tmpfiles.rules = [
    "d /root/backup 0750 vlp vlp - -"
  ];

  # Systemd service to unlock LUKS disk at boot
  # This runs after agenix secrets are available
  systemd.services.luks-sdb1-unlock = {
    description = "Unlock LUKS encrypted disk on sdb1";
    wantedBy = [ "multi-user.target" ];
    # Wait for local filesystem and ensure agenix has decrypted secrets
    after = [ "local-fs.target" ];
    before = [ "mnt-encrypted.mount" ];
    # Require that the secret file exists before running
    unitConfig = {
      ConditionPathExists = config.age.secrets.luks_sdb1.path;
    };
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Group = "root";
    };
    
    script = ''
      # Check if device exists
      if [ ! -b /dev/sdb1 ]; then
        echo "Device /dev/sdb1 not found, skipping LUKS unlock"
        exit 0
      fi
      
      # Check if already unlocked
      if [ -b /dev/mapper/luks-sdb1 ]; then
        echo "LUKS device already unlocked"
        exit 0
      fi
      
      # Unlock the LUKS device using the password from agenix
      echo "Unlocking LUKS device on /dev/sdb1"
      ${pkgs.cryptsetup}/bin/cryptsetup luksOpen /dev/sdb1 luks-sdb1 \
        --key-file ${config.age.secrets.luks_sdb1.path} || {
        echo "Failed to unlock LUKS device,  boot will continue without it"
        exit 0
      }
      
      echo "LUKS device unlocked successfully"
    '';
  };

  # Mount the unlocked LUKS device
  fileSystems."/root/backup" = {
    device = "/dev/mapper/luks-sdb1";
    fsType = "ext4";
    # Use nofail to allow boot to continue if disk is not available
    # This is critical for preventing boot hangs
    options = [ "nofail" ];
  };
}
