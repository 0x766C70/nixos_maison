{
  config,
  pkgs,
  ...
}:
{
 # Firewall configuration                                                                                                                                                                                                                                                    
  networking.nftables.enable = true;                                                                                                                                                                                                                                          
  networking.firewall = {                                                                                                                                                                                                                                                     
    enable = true;                                                                                                                                                                                                                                                            
    allowedTCPPorts = [ 80 443 1337 8000 8022 8023 8024 8080 8200 5432];                                                                                                                                                                                                      
    allowedUDPPorts = [ 8200 ];                                                                                                                                                                                                                                               
  };                                                                                                                                                                                                                                                                          
  networking.nat = {                                                                                                                                                                                                                                                          
     enable = true;                                                                                                                                                                                                                                                           
     internalInterfaces = [ "incusbr1" ];                                                                                                                                                                                                                                     
     externalInterface = "tun0";                                                                                                                                                                                                                                              
     forwardPorts = [                                                                                                                                                                                                                                                         
       {                                                                                                                                                                                                                                                                      
         sourcePort = 8022;                                                                                                                                                                                                                                                   
         proto = "tcp";                                                                                                                                                                                                                                                       
         destination = "192.168.101.11:22";                                                                                                                                                                                                                                   
       }                                                                                                                                                                                                                                                                      
       {                                                                                                                                                                                                                                                                      
         sourcePort = 8023;                                                                                                                                                                                                                                                   
         proto = "tcp";                                                                                                                                                                                                                                                       
         destination = "192.168.101.12:22";                                                                                                                                                                                                                                   
       }                                                                                                                                                                                                                                                                      
       {                                                                                                                                                                                                                                                                      
         sourcePort = 8024;                                                                                                                                                                                                                                                   
         proto = "tcp";                                                                                                                                                                                                                                                       
         destination = "192.168.101.13:22";                                                                                                                                                                                                                                   
       }                                                                                                                                                                                                                                                                      
       {                                                                                                                                                                                                                                                                      
         sourcePort = 8025;                                                                                                                                                                                                                                                   
         proto = "tcp";                                                                                                                                                                                                                                                       
         destination = "192.168.101.14:22";                                                                                                                                                                                                                                   
       }                     
       {                                                                                                                                                                                                                                                                      
         sourcePort = 8026;                                                                                                                                                                                                                                                   
         proto = "tcp";                                                                                                                                                                                                                                                       
         destination = "192.168.101.15:22";
       }
       {
         sourcePort = 53;
         proto = "udp";
         destination = "192.168.101.14:22";
       }
       {
         sourcePort = 50433;
         proto = "udp";
         destination = "192.168.101.15:50433";
       }
     ];
  };
  networking.firewall.trustedInterfaces = [ "incusbr0" ];
}
