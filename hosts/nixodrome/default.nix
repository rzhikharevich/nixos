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
    (inputs.self + /modules/tailscale.nix)
    (inputs.self + /modules/systemd-networkd.nix)
  ];

  networking.hostName = "nixodrome";
  networking.hostId = "69ba052a";

  users.users.roman.uid = 1001;

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

  system.stateVersion = "25.11";
}
