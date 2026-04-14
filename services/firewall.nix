{ config
, pkgs
, ...
}:
{
  # Firewall configuration
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 1337 51413 ];
    allowedUDPPorts = [ 51413 ]; # Transmission µTP + DHT peer discovery
    interfaces."tailscale0".allowedTCPPorts = [ 8096 9091 ];
  };
 

  # 80 - 443 Caddy/nextcloud
  # 1337 - ssh avec fail2ban
  # 8096 - jellyfun only on tailscale


  networking.nat = {
    enable = true;
    internalInterfaces = [ "incusbr1" "ve-+"];
    externalInterface = "eno1";
    forwardPorts = [
    # webserver ssh access
      {
        sourcePort = 8022;
        proto = "tcp";
        destination = "192.168.101.11:22";
      }
    ];
  };
  networking.firewall.trustedInterfaces = [ "incusbr0" "ve-+" ];

}
