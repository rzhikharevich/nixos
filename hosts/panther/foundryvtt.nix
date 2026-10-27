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
      "zfs.target"
      "disko-zfs.service"
    ];
    requires = [
      "zfs.target"
      "disko-zfs.service"
    ];
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
