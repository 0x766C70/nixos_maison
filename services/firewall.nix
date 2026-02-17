{ config
, pkgs
, ...
}:
{
  # Firewall configuration
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 1337 8022 8023 8024 8085];
  };
  # 80 - 443 Caddy/nextcloud
  # 8082 - ssh to webserver
  # 8083 - ssh to new-dl
  # 8024 - ssh to vlaptop
  # 8085 - headscale

  networking.nat = {
    enable = true;
    internalInterfaces = [ "incusbr1" ];
    externalInterface = "tun0";
    forwardPorts = [
      # webserver ssh access
      {
        sourcePort = 8022;
        proto = "tcp";
        destination = "192.168.101.11:22";
      }
      # transmission ssh access
      {
        sourcePort = 8023;
        proto = "tcp";
        destination = "192.168.101.12:22";
      }
      # vlaptop ssh access
      {
        sourcePort = 8024;
        proto = "tcp";
        destination = "192.168.101.13:22";
      }
    ];
  };
  networking.firewall.trustedInterfaces = [ "incusbr0" ];
}
