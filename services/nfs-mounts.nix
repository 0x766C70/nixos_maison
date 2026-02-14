{ config
, pkgs
, ...
}:
{
  # NAS folder mounting
  systemd.tmpfiles.rules = [
    "d /mnt/animations 0751 vlp vlp - -"
    "d /mnt/audio 0751 vlp vlp - -"
    "d /mnt/docu 0755 vlp vlp - -"
    "d /mnt/ebooks 0755 vlp vlp - -"
    "d /mnt/games 0755 vlp vlp - -"
    "d /mnt/movies 0755 vlp vlp - -"
    "d /mnt/tvshows 0755 vlp vlp - -"
    "d /mnt/downloads 0775 vlp vlp - -"
    "d /root/backup 0750 root root - -"
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
