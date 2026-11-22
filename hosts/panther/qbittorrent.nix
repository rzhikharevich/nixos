{ config, ... }:

let
  downloadDir = "/ark/downloads";
  webuiPort = toString config.services.qbittorrent.webuiPort;
in

{
  services.qbittorrent = {
    enable = true;
    serverConfig = {
      LegalNotice.Accepted = true;
      BitTorrent.Session = {
        DefaultSavePath = downloadDir;
        Encryption = 1; # Require encryption.
      };
      WebUI.Address = "127.0.0.1";
    };
    webuiPort = 30001;
  };

  systemd.services.qbittorrent = {
    requires = [ "ark-permissions.service" ];
    after = [ "ark-permissions.service" ];
    unitConfig = {
      RequiresMountsFor = downloadDir;
      AssertPathIsMountPoint = downloadDir;
    };
  };

  networking.nftables.tables.qbittorrent-local = {
    family = "inet";
    content = ''
      chain output {
        type filter hook output priority filter; policy accept;
        ip daddr 127.0.0.1 tcp dport ${webuiPort} meta skuid != ${toString config.users.users.nginx.uid} drop;
        ip6 daddr ::1 tcp dport ${webuiPort} meta skuid != ${toString config.users.users.nginx.uid} drop;
      }
    '';
  };
}
