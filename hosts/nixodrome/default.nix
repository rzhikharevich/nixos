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
  ];

  networking.hostName = "nixodrome";
  networking.hostId = "69ba052a";

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
    package =
      inputs.foundryvtt.packages.${pkgs.stdenv.hostPlatform.system}.foundryvtt_13.overrideAttrs
        (_: {
          majorVersion = "13";
          build = "348";
        });
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

  services.tailscale.enable = true;

  services.syncthing = {
    enable = true;
    dataDir = "/ark/syncthing";
    settings = {
      options = {
        relaysEnabled = false;
        urAccepted = -1;
      };
      devices = {
        iphone.id = "DZ7EN2F-I64TTJS-FVUYRCR-SCMRWDF-GMXYRZL-2XHYVQ6-CPLGUKB-LGVQJQH";
        secretive.id = "QLFTICR-PDD46YZ-JXYXTW6-UDKK3H3-CULJHZA-WYIWO6Z-NOWNVW5-NEPWZQT";
      };
      folders = {
        "Documents" = {
          path = "/ark/syncthing/Documents";
          devices = [ "iphone" "secretive" ];
        };
      };
    };
  };

  systemd.services.syncthing = {
    after = [ "zfs.target" ];
    requires = [ "zfs.target" ];
  };

  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 21027 22000 ];
  };

  system.stateVersion = "25.11";
}
