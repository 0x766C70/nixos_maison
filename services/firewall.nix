{ config
, pkgs
, ...
}:
{
  # Firewall configuration
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 1337 8085];
  };
  
  # 80 - 443 Caddy/nextcloud
  # 1337 - ssh avec fail2ban
  # 8085 - headscale

  networking.nat = {
    enable = true;
    internalInterfaces = [ "incusbr1" "ve-+"];
    externalInterface = "tun0";
  };
  networking.firewall.trustedInterfaces = [ "incusbr0" ];
}
