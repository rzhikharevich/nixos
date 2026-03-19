{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.rzhikharevich) startUserUnit stopUserUnit;
in
{
  users.users.roman = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "input"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
  };

  home-manager.users.roman = {
    imports = [
      ./niri.nix
      ./hyprlock.nix
      ./firefox.nix
      ./waybar.nix
      ./swaync.nix
    ];

    home.packages = [
      (pkgs.writePython3Script "cownix" {
        libraries = [ pkgs.python3Packages.asyncinotify ];
      } (builtins.readFile ../../scripts/cownix.py))
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

    fonts.fontconfig.defaultFonts.monospace = [ "JetBrains Mono" ];
    fonts.fontconfig.defaultFonts.sansSerif = [ "Cantarell" ];

    stylix = {
      fonts = {
        monospace = {
          package = pkgs.jetbrains-mono;
          name = "JetBrains Mono";
        };
        sansSerif = {
          package = pkgs.cantarell-fonts;
          name = "Cantarell";
        };
        sizes = {
          desktop = 14;
          popups = 14;
        };
      };
      image = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/rzhikharevich/nixos-artefacts/f6e480efbf530c6eeeba2d361a7afab7ac322a6b/wallpapers/GreatWave.jpg";
        hash = "sha256-RKhIar3wMwo/5rWG5AdQbnOP4HX+C138Q5YeNY/acgY=";
      };
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      # polarity = "dark";
      icons = {
        enable = true;
        package = pkgs.colloidIcons;
        light = "Colloid-Grey-Light";
        dark = "Colloid-Grey-Dark";
      };
    };

    programs.fuzzel = {
      enable = true;
      settings.main = {
        line-height = 44;
        width = 35;
        vertical-pad = 12;
        inner-pad = 8;
        border-radius = 12;
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
        base_keymap = "VSCode";
        wrap_guides = [ 100 ];
        hour_format = "hour24";
        auto_update = false;

        node = {
          path = lib.getExe pkgs.nodejs;
          npm_path = lib.getExe' pkgs.nodejs "npm";
        };

        lsp = {
          rust-analyzer = {
            binary = {
              path = lib.getExe' config.rzhikharevich.rustToolchain "rust-analyzer";
            };
          };
          nil = {
            binary = {
              path = lib.getExe pkgs.nil;
            };
          };
        };

        languages = {
          Nix = {
            tab_size = 2;
          };
        };
      };
      extensions = [
        "toml"
        "nix"
      ];
    };

    systemd.user.services =
      let
        user = config.users.users.roman;
      in
      lib.genAttrs [ "swaybg" "swayidle" ] (appName: {
        Service = lib.mkMerge [
          config.rzhikharevich.hardeningDefaults
          (lib.mkHardenedUserService user appName { })
        ];
      })
      // {
        roland = {
          Unit = {
            Description = "Touch gestures";
            PartOf = "graphical-session.target";
            After = "graphical-session.target";
          };
          Service = {
            ExecStart = "${pkgs.roland}/bin/roland --config /home/roman/.config/roland/config.toml";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };

    xdg.configFile."roland/config.toml".source = ./roland-config.toml;

    home.stateVersion = "25.11";
  };
}
