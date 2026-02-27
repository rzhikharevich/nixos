{ config, pkgs, lib, ... }:
{
  users.users.roman = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
  };

  home-manager.users.roman = {
    imports = [ ./niri.nix ];
    programs.fish.enable = true;
    programs.foot.enable = true;
    programs.swaylock.enable = true;

    services.swayidle = {
      enable = true;
      events = {
        before-sleep = "${pkgs.niri} msg action power-off-monitors";
        after-resume = "${pkgs.niri} msg action power-on-monitors";
      };
      timeouts = [
        { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock & ${pkgs.systemd}/bin/systemctl suspend"; }
      ];
    };

    services.wluma = {
      enable = true;
      settings = {
        als.iio = {
          path = "/sys/bus/iio/devices";
          thresholds = {
            "0" = "night";
            "10" = "dark";
            "50" = "dim";
            "150" = "normal";
            "300" = "bright";
            "400" = "outdoors";
          };
        };
        output.backlight = [
          {
            name = "eDP-1";
            path = "/sys/class/backlight/amdgpu_bl1";
            capturer = "none";
          }
        ];
      };
    };

    stylix = {
      image = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/rzhikharevich/nixos-artefacts/f6e480efbf530c6eeeba2d361a7afab7ac322a6b/wallpapers/GreatWave.jpg";
        hash = "sha256-RKhIar3wMwo/5rWG5AdQbnOP4HX+C138Q5YeNY/acgY=";
      };
      polarity = "dark";
      icons = {
        enable = true;
        package = pkgs.colloid-icon-theme.override {
          colorVariants = ["grey"];
        };
        light = "Colloid";
        dark = "Colloid-Dark";
      };
    };

    programs.claude-code = {
      enable = true;
      rules = {
        rust-code-style = ./claude/rules/rust-code-style.md;
      };
    };

    programs.firefox = {
       enable = true;
       profiles = {
          default = {
            settings = {
              # "gfx.webrender.all" = true;
              # "layers.acceleration.force-enabled" = true;
              # "widget.dmabuf.force-enabled" = true;
              "dom.min_background_timeout_value" = 10000;
              "beacon.enabled" = false;
            };
          };
       };
    };
    stylix.targets.firefox.profileNames = [ "default" ];

    programs.zed-editor = {
        enable = true;
    };

    systemd.user.services =
      let user = config.users.users.roman;
      in lib.genAttrs [ "swaybg" "swayidle" "wluma" ] (appName: {
        Service = lib.mkMerge [
          config.rzhikharevich.hardeningDefaults
          (lib.mkHardenedUserService user appName)
        ];
      });

    home.stateVersion = "25.11";
  };
}
