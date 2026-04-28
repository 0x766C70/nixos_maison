{ config
, lib
, pkgs
, ...
}:
{
  services.caddy = {
    enable = true;
    virtualHosts."nuage.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://localhost:8080 {
        # Pass real client IP to Nextcloud
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0770 caddy caddy -"
  ];
}
