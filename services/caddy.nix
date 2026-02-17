{ config
, pkgs
, ...
}:
{
  services.caddy = {
    enable = true;
    
    # Global logging configuration for fail2ban integration
    globalConfig = ''
      log {
        output file /var/log/caddy/access.log
        format json
      }
    '';
    
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
  };
  
  # Ensure log directory exists with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0750 caddy caddy -"
  ];
}
