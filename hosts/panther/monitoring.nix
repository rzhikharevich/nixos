{
  config,
  lib,
  pkgs,
  ...
}:

let
  grafanaHost = "grafana.unholy.systems";
  exporters = config.services.prometheus.exporters;
  victoriaMetrics = config.services.victoriametrics;

  scrapeJob = name: target: interval: {
    job_name = name;
    scrape_interval = interval;
    static_configs = [
      {
        targets = [ target ];
        labels.host = config.networking.hostName;
      }
    ];
  };
  exporterJob =
    name: interval: scrapeJob name "127.0.0.1:${toString exporters.${name}.port}" interval;

  dashboards = import ./monitoring-dashboards.nix {
    inherit lib;
    host = config.networking.hostName;
  };
  dashboardFiles = pkgs.linkFarm "panther-grafana-dashboards" (
    lib.mapAttrsToList (name: dashboard: {
      name = "${name}.json";
      path = pkgs.writeText "${name}.json" (builtins.toJSON dashboard);
    }) dashboards
  );
in

{
  sops.secrets = lib.genAttrs [ "grafana-admin-password" "grafana-secret-key" ] (_: {
    # Admin password is set on DB initialization only (?).
    owner = "grafana";
    restartUnits = [ "grafana.service" ];
  });

  services.prometheus.exporters = {
    node = {
      enable = true;
      listenAddress = "127.0.0.1";
      enabledCollectors = [ "systemd" ];
    };
    zfs = {
      enable = true;
      listenAddress = "127.0.0.1";
      pools = [
        "rpool"
        "ark"
      ];
    };
    smartctl = {
      enable = true;
      listenAddress = "127.0.0.1";
    };
  };

  services.victoriametrics = {
    enable = true;
    listenAddress = "127.0.0.1:8428";
    retentionPeriod = "90d";
    prometheusConfig = {
      global = {
        scrape_interval = "30s";
        scrape_timeout = "10s";
      };
      scrape_configs = [
        (exporterJob "node" "30s")
        (exporterJob "zfs" "60s")
        (exporterJob "smartctl" "5m")
        (scrapeJob "victoriametrics" victoriaMetrics.listenAddress "30s")
      ];
    };
  };

  services.grafana = {
    enable = true;
    declarativePlugins = [ pkgs.grafanaPlugins.prometheus ];
    settings = {
      server = {
        http_addr = "127.0.0.1";
        domain = grafanaHost;
        root_url = "https://${grafanaHost}/";
      };
      security = {
        admin_password = "$__file{${config.sops.secrets.grafana-admin-password.path}}";
        secret_key = "$__file{${config.sops.secrets.grafana-secret-key.path}}";
        cookie_secure = true;
      };
      users.allow_sign_up = false;
      "auth.anonymous".enabled = false;
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "VictoriaMetrics";
          uid = "victoriametrics";
          type = "prometheus";
          access = "proxy";
          url = "http://${victoriaMetrics.listenAddress}";
          isDefault = true;
          editable = false;
          jsonData.timeInterval = "30s";
        }
      ];
      dashboards.settings.providers = [
        {
          name = "panther";
          folder = "Panther";
          options.path = dashboardFiles;
        }
      ];
    };
  };
}
