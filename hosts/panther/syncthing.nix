{ config, ... }:

{
  sops.secrets.syncthing-gui = {
    owner = config.services.syncthing.user;
    group = config.services.syncthing.group;
    restartUnits = [ "syncthing-init.service" ];
  };

  services.syncthing = {
    enable = true;
    dataDir = "/ark/syncthing";
    guiPasswordFile = config.sops.secrets.syncthing-gui.path;
    settings = {
      options = {
        relaysEnabled = false;
        urAccepted = -1;
        localAnnounceEnabled = false;
      };
      devices = {
        iphone.id = "DZ7EN2F-I64TTJS-FVUYRCR-SCMRWDF-GMXYRZL-2XHYVQ6-CPLGUKB-LGVQJQH";
        secretive.id = "QLFTICR-PDD46YZ-JXYXTW6-UDKK3H3-CULJHZA-WYIWO6Z-NOWNVW5-NEPWZQT";
        tenserise.id = "C4CSVFC-ZUUKK3U-TGTEZ5N-R5OYHBC-GNX3FFI-RMOY7VE-XMVE6G3-AHJWWAT";
      };
      folders.Documents = {
        path = "${config.services.syncthing.dataDir}/Documents";
        devices = [
          "iphone"
          "secretive"
        ];
      };
    };
  };

  systemd.services.syncthing = {
    requires = [ "ark-permissions.service" ];
    after = [ "ark-permissions.service" ];
    unitConfig = {
      RequiresMountsFor = config.services.syncthing.dataDir;
      AssertPathIsMountPoint = config.services.syncthing.dataDir;
    };
  };

  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      21027
      22000
    ];
  };

  networking.nftables.tables.syncthing-gui = {
    family = "inet";
    content = ''
      chain output {
        type filter hook output priority filter; policy accept;
        ip daddr 127.0.0.1 tcp dport 8384 meta skuid != ${toString config.users.users.syncthing.uid} drop;
        ip6 daddr ::1 tcp dport 8384 meta skuid != ${toString config.users.users.syncthing.uid} drop;
      }
    '';
  };
}
