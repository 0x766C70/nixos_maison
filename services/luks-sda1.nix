{ config, pkgs, lib, ... }:

{
  # Create mount point for the LUKS encrypted disk
  systemd.tmpfiles.rules = [
    "d /mnt/downloads 0750 vlp vlp - -"
  ];

  # Systemd service to unlock LUKS disk at boot
  # This runs after agenix secrets are available
  systemd.services.luks-sda1-unlock = {
    description = "Unlock LUKS encrypted disk on sda1";
    wantedBy = [ "multi-user.target" ];
    # Wait for local filesystem and ensure agenix has decrypted secrets
    after = [ "local-fs.target" ];
    before = [ "mnt-downloads.mount" ];
    # Require that the secret file exists before running
    unitConfig = {
      ConditionPathExists = config.age.secrets.luks_sda1.path;
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Group = "root";
    };

    script = ''
      # Check if device exists
      if [ ! -b /dev/sda1 ]; then
        echo "Device /dev/sda1 not found, skipping LUKS unlock"
        exit 0
      fi

      # Check if already unlocked
      if [ -b /dev/mapper/luks-sda1 ]; then
        echo "LUKS device already unlocked"
        exit 0
      fi

      # Unlock the LUKS device using the password from agenix
      echo "Unlocking LUKS device on /dev/sda1"
      ${pkgs.cryptsetup}/bin/cryptsetup luksOpen /dev/sda1 luks-sda1 \
        --key-file ${config.age.secrets.luks_sda1.path} || {
        echo "Failed to unlock LUKS device, boot will continue without it"
        exit 0
      }

      echo "LUKS device unlocked successfully"
    '';
  };

  # Mount the unlocked LUKS device
  fileSystems."/mnt/downloads" = {
    device = "/dev/mapper/luks-sda1";
    fsType = "ext4";
    # Use nofail to allow boot to continue if disk is not available
    # This is critical for preventing boot hangs
    options = [ "nofail" ];
  };

  # Fix ownership/permissions on the downloads mount root after mount
  # The ext4 filesystem root is typically owned by root; this corrects it
  # so that vlp can read and traverse the mount point.
  systemd.services.luks-sda1-fixperms = {
    description = "Fix permissions on LUKS downloads mount point";
    wantedBy = [ "multi-user.target" ];
    after = [ "mnt-downloads.mount" ];
    wants = [ "mnt-downloads.mount" ];
    # Only run when the disk is actually mounted; skip gracefully otherwise
    unitConfig.ConditionPathIsMountPoint = "/mnt/downloads";

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Group = "root";
    };

    script = ''
      set -e
      chown vlp:users /mnt/downloads -R
      chmod 0750 /mnt/downloads -R
    '';
  };
}
