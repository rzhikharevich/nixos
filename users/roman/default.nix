{ config, pkgs, lib, ... }:
let
  inherit (config.rzhikharevich) startUserUnit stopUserUnit;
  colloidIcons = pkgs.colloid-icon-theme.override { colorVariants = ["grey"]; };
  keyboardIcon = pkgs.runCommand "keyboard-icon.png" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
    rsvg-convert -w 64 -h 64 \
      ${colloidIcons}/share/icons/Colloid-Grey-Dark/actions/24/input-keyboard-virtual-show.svg \
      -o $out
  '';
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

    home.packages = [
      (pkgs.writers.writePython3Bin "cownix" { flakeIgnore = [ "E265" "E501" ]; } (builtins.readFile ../../scripts/cownix.py))
    ];

    programs.fish.enable = true;
    programs.foot.enable = true;

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = lib.mkForce "prefer-dark";
    };

    systemd.user.targets.user-sleep = {
      Unit.Description = "User sleep target";
    };

    services.swayidle = {
      enable = true;
      extraArgs = [ "-w" ];
      events = {
        before-sleep = "${startUserUnit "user-sleep.target"}";
        after-resume = stopUserUnit "user-sleep.target";
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
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      # polarity = "dark";
      icons = {
        enable = true;
        package = colloidIcons;
        light = "Colloid-Grey-Light";
        dark = "Colloid-Grey-Dark";
      };
    };

    programs.fuzzel = {
      enable = true;
      settings.main.line-height = 24;
    };

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings.mainBar = {
        layer = "top";
        height = 44;
        modules-left = [ "niri/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "custom/keyboard" "niri/language" "wireplumber" "battery" ];
        "custom/keyboard" = {
          format = " ";
          tooltip-format = "Toggle on-screen keyboard";
          on-click = "pkill -SIGRTMIN wvkbd-deskintl";
        };
      };
      style = ''
        window#waybar {
          background-color: alpha(@base00, 0.85);
        }

        #custom-keyboard {
          background-image: url("${keyboardIcon}");
          background-size: contain;
          background-repeat: no-repeat;
          background-position: center;
          min-width: 24px;
          padding: 0 8px;
        }

        #workspaces button {
          margin: 2px 2px;
          background-color: @base02;
        }

        #workspaces button.active {
          background-color: @base0D;
          color: @base00;
        }
      '';
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
