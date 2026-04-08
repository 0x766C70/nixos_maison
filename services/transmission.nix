{ config
, lib
, pkgs
, ...
}:
let
  transmissionWritePaths = [
    "/var/lib/transmission" # Config/state directory (managed by the NixOS module)
    "/mnt/downloads"        # Download directory (download-dir and incomplete-dir)
    "/mnt/games"        # Games directory
  ];

  settingsFormat = pkgs.formats.json { };
  settingsFile = settingsFormat.generate "settings.json" config.services.transmission.settings;
  settingsDir = ".config/transmission-daemon";
in
{
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    webHome = pkgs.flood-for-transmission;
    credentialsFile = lib.mkDefault (pkgs.writeText "empty-credentials.json" "{}");
    settings = {
      incomplete-dir = "/mnt/downloads/.incomplete/";
      download-dir = "/mnt/downloads/";
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist = "dl.vlp.fdn.fr";
      rpc-whitelist = "127.0.0.1";
    };
  };

  # Systemd confinement and hardening for the Transmission service
  systemd.services.transmission = {
    confinement = {
      enable = true;
      mode = "full-apivfs";
    };
    serviceConfig = {
      ProtectSystem = "strict";
      PrivateTmp = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      BindPaths = transmissionWritePaths;
      ReadWritePaths = transmissionWritePaths;
      RootDirectory = lib.mkForce "/run/confinement/transmission";
      RootDirectoryStartOnly = lib.mkForce false;
      ExecStartPre = lib.mkForce [
        (
          "+"
          + pkgs.writeShellScript "transmission-prestart" ''
            set -eu
            ${pkgs.jq}/bin/jq --slurp add \
              '${settingsFile}' \
              '${config.services.transmission.credentialsFile}' \
              > '${config.services.transmission.home}/${settingsDir}/settings.json'
            ${pkgs.coreutils}/bin/chmod 600 \
              '${config.services.transmission.home}/${settingsDir}/settings.json'
            ${pkgs.coreutils}/bin/chown \
              '${config.services.transmission.user}:${config.services.transmission.group}' \
              '${config.services.transmission.home}/${settingsDir}/settings.json'
          ''
        )
      ];
    };
  };
}
