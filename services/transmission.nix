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
      rpc-host-whitelist = "dl.vlp.fdn.fr";
      rpc-whitelist = "127.0.0.1";
    };
  };
}
