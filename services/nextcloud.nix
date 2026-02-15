{ config
, pkgs
, lib
, ...
}:
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "localhost";
    database.createLocally = true;
    configureRedis = true;
    maxUploadSize = "1G";
    https = true;
    autoUpdateApps.enable = true;
    config = {
      adminpassFile = config.age.secrets.nextcloud.path;
      dbtype = "pgsql";
    };
    settings = {
      overwriteProtocol = "https";
      default_phone_region = "FR";
      trusted_domains = [ "nuage.vlp.fdn.fr" ];
      trusted_proxies = [ "192.168.1.42" ];
      log_type = "file";
      memories.exiftool = "${lib.getExe pkgs.exiftool}";
      enabledPreviewProviders = [
        "OC\\Preview\\BMP"
        "OC\\Preview\\PDF"
        "OC\\Preview\\Movie"
        "OC\\Preview\\GIF"
        "OC\\Preview\\JPEG"
        "OC\\Preview\\Krita"
        "OC\\Preview\\MarkDown"
        "OC\\Preview\\MP3"
        "OC\\Preview\\OpenDocument"
        "OC\\Preview\\PNG"
        "OC\\Preview\\TXT"
        "OC\\Preview\\XBitmap"
        "OC\\Preview\\HEIC"
      ];
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) news bookmarks contacts calendar tasks cookbook notes memories previewgenerator deck;
    };
    extraAppsEnable = true;
    phpOptions."opcache.interned_strings_buffer" = "13";
  };
  services.nginx.virtualHosts."localhost".listen = [{ addr = "127.0.0.1"; port = 8080; }];
}
