{ config, pkgs, lib, ... }:
let inherit (config.rzhikharevich) startUserUnit stopUserUnit;
in {
  users.users.roman = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
  };

  home-manager.users.roman = {
    imports = [ ./niri.nix ./hyprlock.nix ./firefox.nix ];
    programs.fish.enable = true;
    programs.foot.enable = true;
    systemd.user.targets.user-sleep = {
      Unit.Description = "User sleep target";
    };

    services.swayidle = {
      enable = true;
      extraArgs = [ "-w" ];
      events = {
        before-sleep = (startUserUnit "user-sleep.target");
        after-resume = (stopUserUnit "user-sleep.target");
      };
      timeouts = [
        {
          timeout = 600;
          command = startUserUnit "hyprlock";
        }
        {
          timeout = 630;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
    };

    services.wluma = {
      enable = true;
      settings = {
        als.iio = {
          path = "/sys/bus/iio/devices";
          thresholds = {
            "0" = "night";
            "1" = "dark";
            "2" = "dim";
            "5" = "normal";
            "10" = "bright";
            "20" = "outdoors";
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

    fonts.fontconfig.defaultFonts.monospace = [ "JetBrains Mono" ];

    stylix = {
      fonts.monospace = {
        package = pkgs.jetbrains-mono;
        name = "JetBrains Mono";
      };
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

    programs.zed-editor = {
        enable = true;
        userSettings = {
          wrap_guides = [ 100 ];
        };
    };

    systemd.user.services =
      let user = config.users.users.roman;
      in
        lib.genAttrs [ "swaybg" "swayidle" ] (appName: {
          Service = lib.mkMerge [
            config.rzhikharevich.hardeningDefaults
            (lib.mkHardenedUserService user appName {})
          ];
        }) //
        lib.genAttrs [ "wluma" ] (appName: {
          Service = lib.mkMerge [
            config.rzhikharevich.hardeningDefaults
            (lib.mkHardenedUserService user appName { usesShareDir = true; })
          ];
        });

    home.stateVersion = "25.11";
  };
}
