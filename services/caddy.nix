{ config
, pkgs
, ...
}:
{
  services.caddy = {
    enable = true;
    virtualHosts."dl.vlp.fdn.fr".extraConfig = ''
      basic_auth {
        mlc {file.${config.age.secrets.caddy_mlc.path}}
      }
      reverse_proxy http://localhost:9091
    '';
    virtualHosts."nuage.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://localhost:8080
    '';
    virtualHosts."laptop.vlp.fdn.fr".extraConfig = ''
      basic_auth / {
        vlp {file.${config.age.secrets.caddy_vlp.path}}
      }
      reverse_proxy http://192.168.101.13:7681
    '';
    virtualHosts."web.vlp.fdn.fr".extraConfig = ''
      reverse_proxy 192.168.101.11:80
    '';
    virtualHosts."farfadet.web.vlp.fdn.fr".extraConfig = ''
      reverse_proxy 192.168.101.11:80
    '';
    virtualHosts."cv.web.vlp.fdn.fr".extraConfig = ''
      reverse_proxy 192.168.101.11:80
    '';
    virtualHosts."ai.web.vlp.fdn.fr".extraConfig = ''
      reverse_proxy 192.168.101.11:80
    '';
    virtualHosts."hs.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://127.0.0.1:8085
    '';
    # Homepage dashboard - family portal
    virtualHosts."home.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://127.0.0.1:8082
    '';
    # Jellyfin media server
    virtualHosts."media.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://127.0.0.1:8096
    '';
    # Uptime monitoring
    virtualHosts."status.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://127.0.0.1:3001
    '';
    # Paperless document management
    virtualHosts."docs.vlp.fdn.fr".extraConfig = ''
      reverse_proxy http://127.0.0.1:28981
    '';
  };
}
