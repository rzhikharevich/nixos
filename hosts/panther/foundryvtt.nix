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
    after = [
      "zfs-import-ark.service"
      "disko-zfs.service"
      "zfs-mount.service"
      "zfs.target"
    ];
    requires = [
      "zfs-import-ark.service"
      "disko-zfs.service"
      "zfs-mount.service"
      "zfs.target"
    ];
    # Never run against the underlying directory if the dataset was not mounted.
    unitConfig.AssertPathIsMountPoint = config.services.foundryvtt.dataDir;
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
