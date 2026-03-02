{ config
, pkgs
, ...
}:
{
  # Tailscale client — so maison can join its own headscale-managed tailnet
  # and reach nodes like azul.tailnet.vlp.fdn.fr for remote backups.
  #
  # After deploying, register once with:
  #   sudo tailscale up --login-server https://hs.vlp.fdn.fr
  # Then approve the node in headscale:
  #   headscale nodes register --user vlp --key <nodekey>
  services.tailscale = {
    enable = true;
    openFirewall = true; # Opens UDP 41641 automatically
  };
}
