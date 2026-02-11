{
  config,
  pkgs,
  ...
}:
{
  services.avahi.enable = true;
  services.minidlna.enable = true;
  services.minidlna.openFirewall = true;
  services.minidlna.settings = {
    friendly_name = "NAS";
    media_dir = [
      "V,/mnt/animations/"
      "V,/mnt/audio/"
      "V,/mnt/movies/"
      "V,/mnt/docu/"
      "V,/mnt/downloads/"
    ];
    log_level = "warn";
    inotify = "yes";
  };

  users.users.minidlna = {
  extraGroups = [ "users" ]; # so minidlna can access the files.
  };
}
