{ config
, pkgs
, ...
}:
{
  # NAS folder mounting
  # These tmpfiles rules define the local mount-point directories and their
  # permissions (owner vlp, mode as shown).  They are created once on
  # boot; the actual file permissions inside each directory are controlled
  # by the NFS server (192.168.1.10).
  # Directories shared with Transmission use group "transmission" (0775 = rwxrwxr-x)
  # so that the Transmission daemon can write to them.  Other directories that
  # are read-only for services use group "vlp" (0755 = rwxr-xr-x).
  # Note: /home/vlp/backup is intentionally absent here – its mount-point
  # and permissions are managed by services/luks-disk.nix.
  systemd.tmpfiles.rules = [
    "d /mnt/animations 0775 vlp transmission - -"
    "d /mnt/audio 0775 vlp transmission - -"
    "d /mnt/docu 0775 vlp transmission - -"
    "d /mnt/ebooks 0775 vlp transmission - -"
    "d /mnt/games 0775 vlp transmission - -"
    "d /mnt/movies 0775 vlp transmission - -"
    "d /mnt/tvshows 0775 vlp transmission - -"
    "d /mnt/downloads 0775 vlp transmission - -"
    "d /home/vlp/partages 0750 vlp vlp - -"
  ];

  fileSystems."/mnt/animations" = {
    device = "192.168.1.10:/data/animations";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/docu" = {
    device = "192.168.1.10:/data/docu";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/ebooks" = {
    device = "192.168.1.10:/data/ebooks";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/games" = {
    device = "192.168.1.10:/data/games";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/movies" = {
    device = "192.168.1.10:/data/movies";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/tvshows" = {
    device = "192.168.1.10:/data/tvshows";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/mnt/audio" = {
    device = "192.168.1.10:/data/audio";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/home/vlp/partages" = {
    device = "192.168.1.10:/data/partages";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
  fileSystems."/var/lib/nextcloud/data" = {
    device = "192.168.1.10:/data/nextcloud";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };
}
