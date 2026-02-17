{ config
, pkgs
, ...
}:
{
  # Grafana - Local monitoring dashboard
  # Complements the cloud-hosted Grafana with local visualization
  
  services.grafana = {
    enable = true;
    
    # Network settings
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3300;
        domain = "grafana.vlp.fdn.fr";
        root_url = "https://grafana.vlp.fdn.fr";
      };
      
      # Security
      security = {
        admin_user = "admin";
        # Admin password will be set on first login
        # Change it immediately!
        secret_key = "changeme_on_first_run";
      };
      
      # Anonymous access for family members (read-only dashboards)
      auth.anonymous = {
        enabled = true;
        org_role = "Viewer"; # Read-only access
      };
      
      # Database (SQLite for simplicity)
      database = {
        type = "sqlite3";
        path = "/var/lib/grafana/data/grafana.db";
      };
      
      # Analytics
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };
    };
    
    # Data sources
    provision = {
      enable = true;
      
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:${toString config.services.prometheus.port}";
            isDefault = true;
            jsonData = {
              timeInterval = "10s";
            };
          }
        ];
      };
      
      # Pre-configured dashboards
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "default";
            orgId = 1;
            folder = "";
            type = "file";
            disableDeletion = false;
            updateIntervalSeconds = 10;
            allowUiUpdates = true;
            options = {
              path = "/var/lib/grafana/dashboards";
            };
          }
        ];
      };
    };
  };
  
  # Install community dashboards
  systemd.services.grafana-setup = {
    description = "Download Grafana community dashboards";
    after = [ "grafana.service" ];
    wantedBy = [ "multi-user.target" ];
    
    script = ''
      set -e
      
      DASHBOARD_DIR="/var/lib/grafana/dashboards"
      mkdir -p "$DASHBOARD_DIR"
      
      # Download Node Exporter dashboard if not exists
      if [ ! -f "$DASHBOARD_DIR/node-exporter.json" ]; then
        echo "Downloading Node Exporter dashboard..."
        ${pkgs.curl}/bin/curl -fsSL \
          https://grafana.com/api/dashboards/1860/revisions/31/download \
          -o "$DASHBOARD_DIR/node-exporter.json"
      fi
      
      # Fix permissions
      chown -R grafana:grafana "$DASHBOARD_DIR"
      
      echo "Grafana dashboards setup complete"
    '';
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
  };
  
  # Security hardening
  systemd.services.grafana = {
    serviceConfig = {
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      ReadWritePaths = [ "/var/lib/grafana" ];
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
    };
  };
}
