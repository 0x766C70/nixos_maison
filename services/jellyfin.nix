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

  # Intel Iris Plus 655 (CoffeeLake, Gen 9.5) — use iHD driver (intel-media-driver).
  # The older i965 driver (vaapiIntel) does NOT support CoffeeLake properly.
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ]; # VA-API / VAAPI for QSV/iHD
  };
}
