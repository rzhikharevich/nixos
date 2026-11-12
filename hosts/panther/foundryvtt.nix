{
  config,
  pkgs,
  inputs,
  ...
}:

{
  services.foundryvtt = {
    enable = true;
    package = (pkgs.callPackage "${inputs.foundryvtt}/pkgs/foundryvtt" { }).overrideAttrs (
      old:
      old
      // {
        majorVersion = "14";
        build = "365";
      }
    );
    hostName = "fvtt.rzhikharevi.ch";
    minifyStaticFiles = true;
    proxySSL = true;
    upnp = false;
    dataDir = "/ark/fvtt";
  };

  systemd.services.foundryvtt = {
    unitConfig = {
      RequiresMountsFor = config.services.foundryvtt.dataDir;
      # Never run against the underlying directory if the dataset was not mounted.
      AssertPathIsMountPoint = config.services.foundryvtt.dataDir;
    };
  };

  networking.nftables.tables.foundryvtt-local = {
    family = "inet";
    content = ''
      chain output {
        type filter hook output priority filter; policy accept;
        ip daddr 127.0.0.1 tcp dport 30000 meta skuid != ${toString config.users.users.nginx.uid} drop;
        ip6 daddr ::1 tcp dport 30000 meta skuid != ${toString config.users.users.nginx.uid} drop;
      }
    '';
  };
}
