{ lib, host }:

let
  selector = ''host="${host}"'';
  datasource = {
    type = "prometheus";
    uid = "victoriametrics";
  };

  query = expr: legendFormat: {
    inherit expr legendFormat;
  };

  pressureQuery =
    metric: legendFormat:
    query "100 * rate(node_pressure_${metric}_seconds_total{${selector}}[$__rate_interval])" legendFormat;

  timeSeries = title: unit: targets: {
    inherit title targets;
    type = "timeseries";
    fieldConfig = {
      defaults = {
        inherit unit;
        min = 0;
      };
      overrides = [ ];
    };
    options = {
      legend = {
        displayMode = "list";
        placement = "bottom";
      };
      tooltip.mode = "multi";
    };
  };

  status = title: values: target: {
    inherit title;
    type = "stat";
    targets = [ (target // { instant = true; }) ];
    fieldConfig = {
      defaults = {
        noValue = "No data";
        color.mode = "thresholds";
        thresholds = {
          mode = "absolute";
          steps = [
            {
              color = "red";
              value = null;
            }
          ];
        };
        mappings = [
          {
            type = "value";
            options = values;
          }
        ];
      };
      overrides = [ ];
    };
    options = {
      colorMode = "background";
      graphMode = "none";
      textMode = "value_and_name";
      reduceOptions = {
        calcs = [ "lastNotNull" ];
        fields = "";
        values = false;
      };
    };
  };

  successValues = {
    "0" = {
      text = "Failed";
      color = "red";
    };
    "1" = {
      text = "OK";
      color = "green";
    };
  };

  dashboard = uid: title: panels: {
    inherit uid title;
    schemaVersion = 39;
    version = 1;
    editable = false;
    tags = [ host ];
    timezone = "browser";
    refresh = "30s";
    time = {
      from = "now-6h";
      to = "now";
    };
    links = [
      {
        type = "dashboards";
        tags = [ host ];
        asDropdown = false;
        includeVars = true;
        keepTime = true;
      }
    ];
    panels = lib.imap0 (
      index: panel:
      panel
      // {
        id = index + 1;
        inherit datasource;
        gridPos = {
          x = lib.mod index 2 * 12;
          y = builtins.div index 2 * 8;
          w = 12;
          h = 8;
        };
        targets = lib.imap0 (
          targetIndex: target:
          {
            inherit datasource;
            refId = builtins.elemAt lib.upperChars targetIndex;
          }
          // target
        ) panel.targets;
      }
    ) panels;
  };
in

{
  host = dashboard "${host}-host" "Panther / Host" [
    (status "Scrape targets" successValues (query "up{${selector}}" "{{job}}"))
    (status "Failed systemd services" {
      "0" = {
        text = "None";
        color = "green";
      };
    } (query ''sum(node_systemd_unit_state{${selector},state="failed"})'' "Failed services"))
    (timeSeries "CPU utilisation" "percent" [
      (query ''100 * (1 - avg(rate(node_cpu_seconds_total{${selector},mode="idle"}[$__rate_interval])))'' "CPU")
    ])
    (timeSeries "Memory utilisation" "percent" [
      (query "100 * (1 - node_memory_MemAvailable_bytes{${selector}} / node_memory_MemTotal_bytes{${selector}})" "Memory")
    ])
    (timeSeries "Pressure stall" "percent" [
      (pressureQuery "cpu_waiting" "CPU some")
      (pressureQuery "memory_waiting" "Memory some")
      (pressureQuery "memory_stalled" "Memory full")
      (pressureQuery "io_waiting" "IO some")
      (pressureQuery "io_stalled" "IO full")
    ])
    (timeSeries "Hardware temperatures" "celsius" [
      (query "node_hwmon_temp_celsius{${selector}}" "{{chip}} / {{sensor}}")
    ])
    (timeSeries "Disk throughput" "Bps" [
      (query "rate(node_disk_read_bytes_total{${selector}}[$__rate_interval])" "{{device}} read")
      (query "rate(node_disk_written_bytes_total{${selector}}[$__rate_interval])" "{{device}} write")
    ])
    (timeSeries "Network throughput" "Bps" [
      (query ''rate(node_network_receive_bytes_total{${selector},device!="lo"}[$__rate_interval])'' "{{device}} receive")
      (query ''rate(node_network_transmit_bytes_total{${selector},device!="lo"}[$__rate_interval])'' "{{device}} transmit")
    ])
  ];

  storage = dashboard "${host}-storage" "Panther / Storage" [
    (status "ZFS pool health" {
      "0" = {
        text = "Online";
        color = "green";
      };
      "1" = {
        text = "Degraded";
        color = "orange";
      };
      "2" = {
        text = "Faulted";
        color = "red";
      };
      "3" = {
        text = "Offline";
        color = "red";
      };
      "4" = {
        text = "Unavailable";
        color = "red";
      };
      "5" = {
        text = "Removed";
        color = "red";
      };
      "6" = {
        text = "Suspended";
        color = "red";
      };
    } (query "zfs_pool_health{${selector}}" "{{pool}}"))
    (status "ZFS collectors" successValues (
      query "zfs_scrape_collector_success{${selector}}" "{{collector}}"
    ))
    (timeSeries "ZFS pool utilisation" "percent" [
      (query "100 * zfs_pool_allocated_bytes{${selector}} / zfs_pool_size_bytes{${selector}}" "{{pool}}")
    ])
    (timeSeries "Dataset space used (excluding children)" "bytes" [
      (query ''zfs_dataset_used_by_dataset_bytes{${selector},type="filesystem"}'' "{{name}}")
    ])
    (status "SMART health" successValues (
      query "smartctl_device_smart_status{${selector}}" "{{device}}"
    ))
    (timeSeries "Disk temperatures" "celsius" [
      (query ''smartctl_device_temperature{${selector},temperature_type="current"}'' "{{device}}")
    ])
    (timeSeries "Drive endurance used (where supported)" "percent" [
      (query "smartctl_device_percentage_used{${selector}}" "{{device}}")
    ])
    (timeSeries "Lifetime media errors (where supported)" "short" [
      (query "smartctl_device_media_errors{${selector}}" "{{device}}")
    ])
  ];
}
