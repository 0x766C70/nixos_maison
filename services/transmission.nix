{ config
, pkgs
, ...
}:
{
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    webHome = pkgs.flood-for-transmission;
    settings = {
      incomplete-dir = "/mnt/downloads/.incomplete/";
      download-dir = "/mnt/downloads/";
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist = "maison.vlpnet.hs.766c70.com";
      rpc-whitelist = "127.0.0.1,100.64.0.4,100.64.0.7,100.64.0.1,100.64.0.10";
      peer-port = 51413;
      peer-port-random-on-start = false;
      utp-enabled = true;
      dht-enabled = true; # Distributed Hash Table — finds peers without a tracker
      pex-enabled = true; # Peer Exchange — peers share their peer lists with you
      lpd-enabled = true; # Local Peer Discovery — useful on LAN
    };
  };

  # Allow the Transmission daemon to write to the NFS-backed games share.
  # The NixOS transmission module runs the daemon in a private chroot
  # (RootDirectory=/run/transmission).  Paths must be explicitly bind-mounted
  # into that chroot via BindPaths to be visible at all — ReadWritePaths alone
  # is insufficient because it only controls write permissions for paths that
  # already exist inside the root.  BindPaths creates a read-write bind mount
  # and is therefore the correct directive here.
  systemd.services.transmission.serviceConfig.BindPaths = [ "/mnt/games" ];
}
