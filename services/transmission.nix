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
in
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
      # The upstream transmission module sets RootDirectoryStartOnly = true so that only
      # ExecStart runs inside its chroot. Confinement.enable is incompatible with that
      # setting (bind-mounts can't be restricted to ExecStart alone), so we override it
      # to false here — all exec phases will run inside the confinement namespace.
      RootDirectoryStartOnly = lib.mkForce false;
    };
  };
}
