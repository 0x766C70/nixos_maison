{
  config,
  pkgs,
  ...
}:
{

  services.transmission = {                                                   
    enable = true;                                                            
    openRPCPort = true;                                                                                                                                      
    settings = {       
      download-dir = "/home/mlc/media/downloads/";                                                                                                           
      rpc-bind-address = "0.0.0.0";                                           
      rpc-host-whitelist = "dl.vlp.fdn.fr";                                   
      rpc-whitelist = "*";                                                                                                                                   
    };                                                                        
  };              

}
