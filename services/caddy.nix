{
  config,
  pkgs,
  ...
}:
{

  age.secrets.dl = {
    file = ../secrets/dl_caddy.age;
  };

services.caddy = {                                                                                                                                                                                                                                                          
    enable = true;                                                                                                                                                                                                                                                            
    virtualHosts."new-dl.vlp.fdn.fr".extraConfig = ''                                                                                                                                                                                                                         
      basic_auth {                                                                                                                                                                                                                                                            
        mlc config.age.secrets.dl_caddy.path                                                                                                                                                                                                      
      }                                                                                                                                                                                                                                                                       
      reverse_proxy http://localhost:9091                                                                                                                                                                                                                                     
    '';                                                                                                                                                                                                                                                                       
    virtualHosts."nuage.vlp.fdn.fr".extraConfig = ''                                                                                                                                                                                                                          
      reverse_proxy http://localhost:8080                                                                                                                                                                                                                                     
    '';                                                                                                                                                                                                                                                                       
    virtualHosts."laptop.vlp.fdn.fr".extraConfig = ''                                                                                                                                                                                                                         
      basic_auth / {                                                                                                                                                                                                                                                          
                vlp $2a$14$PqyFv42lPq5jJa7gE3jYru2lJ6G5Ne5n4euH68Knnjpcd6Hvs2qE.                                                                                                                                                                                              
        }                                                                                                                                                                                                                                                                     
      reverse_proxy http://192.168.101.13:7681                                                                                                                                                                                                                                
    '';                                                                                                                                                                                                                                                                       
    virtualHosts."pihole.vlp.fdn.fr".extraConfig = ''                                                                                                                                                                                                                         
      reverse_proxy 192.168.101.14:80                                                                                                                                                                                                                                         
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
  };                              
}
