{
  config,
  pkgs,
  ...
}:
{
  containers.hugo = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.1.42";
    localAddress = "192.168.1.101";
    config =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {

        system.stateVersion = "24.11";

        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [
              80
              433
            ];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };

        services.resolved.enable = true;

      };
  };
}
