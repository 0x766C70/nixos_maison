{ config
, lib
, pkgs
, ...
}:
let
  # Paths that Transmission must be able to write to.
  # Used in both BindPaths (confinement namespace) and ReadWritePaths (ProtectSystem override).
  transmissionWritePaths = [
    "/var/lib/transmission" # Config/state directory (managed by the NixOS module)
    "/mnt/downloads"        # Download directory (download-dir and incomplete-dir)
  ];

  # Mirror the upstream transmission module's internal let-bindings so we can
  # generate an identical settingsFile path and reference the correct settingsDir.
  settingsFormat = pkgs.formats.json { };
  settingsFile = settingsFormat.generate "settings.json" config.services.transmission.settings;
  settingsDir = ".config/transmission-daemon";
in
{
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    webHome = pkgs.flood-for-transmission;
    # The upstream module defaults credentialsFile to /dev/null, which is used by the
    # prestart script as an empty JSON source for jq.  Inside the confinement's private
    # /dev namespace /dev/null is not available, so we substitute an in-store empty JSON
    # file.  lib.mkDefault lets users still override this with a real credentials file.
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
    # Namespace-based sandboxing: the service runs in a minimal private filesystem.
    # full-apivfs is required for a network daemon (/proc, /sys, /dev and network namespaces).
    confinement = {
      enable = true;
      mode = "full-apivfs";
    };
    serviceConfig = {
      # Read-only root filesystem — only paths in ReadWritePaths can be written to.
      ProtectSystem = "strict";
      # Private /tmp, isolated from other services.
      PrivateTmp = true;
      # Bind the required data directories into the private namespace (confinement requires this).
      BindPaths = transmissionWritePaths;
      # Explicitly allow writes to the above paths (overrides ProtectSystem = "strict").
      ReadWritePaths = transmissionWritePaths;
      # The upstream transmission module sets RootDirectory = "/run/transmission".
      # The confinement module also sets RootDirectory = "/run/confinement/transmission".
      # Both conflict at equal priority, so we force the confinement path here.
      RootDirectory = lib.mkForce "/run/confinement/transmission";
      # The upstream transmission module sets RootDirectoryStartOnly = true so that only
      # ExecStart runs inside its chroot. Confinement.enable is incompatible with that
      # setting (bind-mounts can't be restricted to ExecStart alone), so we override it
      # to false here — all exec phases will run inside the confinement namespace.
      RootDirectoryStartOnly = lib.mkForce false;
      # Override the upstream ExecStartPre to avoid /dev/stdin, which is not available
      # inside the confinement's private /dev namespace.  The upstream script pipes jq
      # output into `install ... /dev/stdin`, which requires /dev/stdin to exist as a
      # stat-able path.  Our replacement writes the merged JSON directly via shell
      # redirection and then fixes ownership/permissions explicitly.
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
