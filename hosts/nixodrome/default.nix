{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./nginx.nix
    (inputs.self + /modules/tailscale.nix)
  ];

  networking.hostName = "nixodrome";
  networking.hostId = "69ba052a";

  sops = {
    defaultSopsFile = inputs.self + /secrets/nixodrome.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.EnableNetworkConfiguration = false;
      Settings.AutoConnect = false;
    };
  };

  systemd.network = {
    enable = true;
    wait-online.enable = false;
    networks = {
      "10-wired" = {
        matchConfig.Type = "ether";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV4Config.RouteMetric = 100;
        ipv6AcceptRAConfig.RouteMetric = 100;
      };

      "20-wireless" = {
        matchConfig.Type = "wlan";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV4Config.RouteMetric = 200;
        ipv6AcceptRAConfig.RouteMetric = 200;
      };
    };
  };

  networking.useDHCP = false;

  services.scx = {
    enable = true;
    package = pkgs.scx.rustscheds;
    scheduler = "scx_lavd";
    extraArgs = [
      "--autopilot"
      "--cpu-pref-order"
      "0-3,4-7,8-11"
    ];
  };

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
    after = [ "zfs.target" ];
    requires = [ "zfs.target" ];
  };

  networking.firewall.enable = true;

  programs.ccache.enable = true;
  nix.settings = {
    extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
    narinfo-cache-negative-ttl = 600;
    narinfo-cache-positive-ttl = 600;
  };

  nixpkgs.overlays = [
    (self: super: {
      ccacheWrapper = super.ccacheWrapper.override {
        extraConfig = ''
          export CCACHE_COMPRESS=1
          export CCACHE_SLOPPINESS=random_seed
          export CCACHE_DIR="${config.programs.ccache.cacheDir}"
          export CCACHE_MAXSIZE="20GiB";
          export CCACHE_UMASK=007
          if [ ! -d "$CCACHE_DIR" ]; then
            echo "====="
            echo "Directory '$CCACHE_DIR' does not exist"
            echo "Please create it with:"
            echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
            echo "  sudo chown root:nixbld '$CCACHE_DIR'"
            echo "====="
            exit 1
          fi
          if [ ! -w "$CCACHE_DIR" ]; then
            echo "====="
            echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
            echo "Please verify its access permissions"
            echo "====="
            exit 1
          fi
        '';
      };
    })
    (self: super: {
      linux-asahi = super.linux-asahi.override {
        callPackage = fn: args: super.callPackage fn (args // { stdenv = self.ccacheStdenv; });
      };
    })
    (self: super: {
      scx = super.scx // {
        rustscheds = super.scx.rustscheds.overrideAttrs (_: {
          meta.badPlatforms = [ ];
        });
      };
    })
  ];

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      extraPools = [ "ark" ];
      requestEncryptionCredentials = true;
    };
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  services.syncthing = {
    enable = true;
    dataDir = "/ark/syncthing";
    guiPasswordFile = "/run/credentials/syncthing.service/gui-password";
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
      folders = {
        "Documents" = {
          path = "/ark/syncthing/Documents";
          devices = [
            "iphone"
            "secretive"
          ];
        };
      };
    };
  };

  systemd.services.syncthing = {
    serviceConfig = {
      LoadCredential = "gui-password:/etc/secrets/syncthing-gui";
    };
    after = [ "zfs.target" ];
    requires = [ "zfs.target" ];
  };

  services.immich = {
    enable = true;
    port = 30001;
    mediaLocation = "/ark/immich";
  };

  systemd.services.immich-server = {
    after = [ "zfs.target" ];
    requires = [ "zfs.target" ];
  };

  services.redis.servers.immich.logLevel = "warning";
  services.postgresql.dataDir = "/ark/postgres";

  systemd.services.postgresql = {
    after = [ "zfs.target" ];
    requires = [ "zfs.target" ];
  };

  systemd.tmpfiles.settings."10-ark" = {
    "/ark/immich".d = {
      user = "immich";
      group = "immich";
      mode = "2775";
    };
    "/ark/postgres".d = {
      user = "postgres";
      group = "postgres";
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
        ip daddr 127.0.0.1 tcp dport 30000 meta skuid != ${toString config.users.users.nginx.uid} drop;
        ip6 daddr ::1 tcp dport 30000 meta skuid != ${toString config.users.users.nginx.uid} drop;
      }
    '';
  };

  sops = {
    secrets = {
      pubproxy-wg-server-pubkey = {};
      pubproxy-wg-client-privkey = {};
    };
    templates."pubproxy-wg.conf" = {
      mode = "0400";
      restartUnits = [ "wg-quick-pubproxy-wg.service" ];

      content = ''
        [Interface]
        Address = 10.77.0.2/24
        PrivateKey = ${config.sops.placeholder.pubproxy-wg-client-privkey}

        [Peer]
        PublicKey = ${config.sops.placeholder.pubproxy-wg-server-pubkey}
        Endpoint = 10.0.0.16:51820
        AllowedIPs = 10.77.0.0/24
        PersistentKeepalive = 25
      '';
    };
  };

  networking.wg-quick.interfaces.pubproxy-wg = {
    configFile = config.sops.templates."pubproxy-wg.conf".path;
  };

  networking.firewall.interfaces.pubproxy-wg.allowedTCPPorts = [
    80
    443
  ];

  system.stateVersion = "25.11";
}
