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
      umask = "0002";
      incomplete-dir = "/mnt/downloads/.incomplete/";
      download-dir = "/mnt/downloads/";
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist = "maison.vlpnet.hs.766c70.com";
      rpc-whitelist = "127.0.0.1,100.64.0.4,100.64.0.7,100.64.0.1,100.64.0.10,100.64.0.3";
      peer-port = 51413;
      peer-port-random-on-start = false;
      ReadWritePaths = [ "/mnt/games" ];
      utp-enabled = true;
      dht-enabled = true; # Distributed Hash Table — finds peers without a tracker
      pex-enabled = true; # Peer Exchange — peers share their peer lists with you
      lpd-enabled = true; # Local Peer Discovery — useful on LAN
    };
  };
}
