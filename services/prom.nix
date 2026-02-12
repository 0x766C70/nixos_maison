{ config
, pkgs
, ...
}:
{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9000;
    enabledCollectors = [ "systemd" ];
    extraFlags = [ "--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" "--collector.wifi" ];
  };

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s"; # "1m"
    checkConfig = "syntax-only";
    scrapeConfigs = [
      {
        job_name = "nuc_node";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
    remoteWrite = [
      {
        url = "https://prometheus-prod-01-eu-west-0.grafana.net/api/prom/push";
        basic_auth = {
          username = "737153";
          password_file = config.age.secrets.prom.path;
        };
      }
    ];
  };

}
