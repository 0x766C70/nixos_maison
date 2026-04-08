{ config
, pkgs
, ...
}:
{
  services.jellyfin = {
    enable = true;
 #   openFirewall = true;
    user = "vlp";
  };
  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
  ];
}
