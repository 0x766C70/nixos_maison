{ config
, pkgs
, ...
}:
{
  # Homepage dashboard for family service access
  services.homepage-dashboard = {
    enable = true;
    
    # Listen on localhost, proxy via Caddy
    listenPort = 8082;
    
    # Configuration
    settings = {
      title = "Maison Family Server";
      favicon = "https://raw.githubusercontent.com/gethomepage/homepage/main/public/logo-light.png";
      
      # Layout
      layout = {
        "Media" = {
          style = "row";
          columns = 3;
        };
        "Cloud & Files" = {
          style = "row";
          columns = 3;
        };
        "System" = {
          style = "row";
          columns = 3;
        };
      };
    };
    
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              icon = "jellyfin.png";
              href = "http://192.168.1.42:8096";
              description = "Movies, TV Shows & Music";
            };
          }
          {
            "MiniDLNA" = {
              icon = "minidlna.png";
              href = "http://192.168.1.42:8200";
              description = "DLNA Media Server";
            };
          }
          {
            "Transmission" = {
              icon = "transmission.png";
              href = "https://dl.vlp.fdn.fr";
              description = "Torrent Downloads";
            };
          }
        ];
      }
      {
        "Cloud & Files" = [
          {
            "Nextcloud" = {
              icon = "nextcloud.png";
              href = "https://nuage.vlp.fdn.fr";
              description = "Personal Cloud Storage";
            };
          }
          {
            "NFS Shares" = {
              icon = "nfs.png";
              description = "Network File Shares";
            };
          }
        ];
      }
      {
        "System" = [
          {
            "AdGuard Home" = {
              icon = "adguard-home.png";
              href = "http://192.168.1.42:3000";
              description = "DNS & Ad Blocker";
            };
          }
          {
            "Grafana" = {
              icon = "grafana.png";
              href = "https://vlpfdnfr.grafana.net";
              description = "Monitoring Dashboard";
            };
          }
          {
            "Headscale" = {
              icon = "headscale.png";
              href = "https://hs.vlp.fdn.fr";
              description = "Mesh VPN Control";
            };
          }
        ];
      }
    ];
    
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        datetime = {
          text_size = "xl";
          format = {
            timeStyle = "short";
            dateStyle = "short";
          };
        };
      }
    ];
  };
  
  # Add systemd service configuration
  systemd.services.homepage-dashboard = {
    serviceConfig = {
      # Security hardening
      DynamicUser = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
    };
  };
}
