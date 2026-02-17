{ config
, pkgs
, ...
}:
{
  # Calibre-web - Ebook library management and reader
  services.calibre-web = {
    enable = true;
    
    # Network settings
    listen = {
      ip = "127.0.0.1";
      port = 8083;
    };
    
    # Configuration
    options = {
      enableBookUploading = true;
      enableBookConversion = true;
      calibreLibrary = "/var/lib/calibre-web/library";
    };
  };
  
  # Install calibre for book conversion
  environment.systemPackages = with pkgs; [
    calibre
  ];
  
  # Create calibre library directory
  systemd.tmpfiles.rules = [
    "d /var/lib/calibre-web 0755 calibre-web calibre-web - -"
    "d /var/lib/calibre-web/library 0755 calibre-web calibre-web - -"
  ];
  
  # Link to ebooks NFS mount (optional)
  # Uncomment if you want to manage existing ebook collection
  # systemd.services.calibre-web.serviceConfig = {
  #   BindReadOnlyPaths = [ "/mnt/ebooks:/var/lib/calibre-web/source" ];
  # };
}
