{
  config,
  pkgs,
  ...
}:
{

  services.transmission = {                                                   
    enable = true;                                                            
    #openRPCPort = true;
    webHome = pkgs.flood-for-transmission; 
    settings = {
      incomplete-dir = "/mnt/downloads/.incomplete/";       
      download-dir = "/mnt/downloads/"; 
      rpc-bind-address = "0.0.0.0";                                           
      rpc-host-whitelist = "new-dl.vlp.fdn.fr";                                   
      rpc-whitelist = "*";                                                                                                                                   
    };                                                                        
  };              

}
