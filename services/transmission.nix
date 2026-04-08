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
      rpc-whitelist = "127.0.0.1,100.64.0.4,100.64.0.7,100.64.0.1";
    };
  };
}
