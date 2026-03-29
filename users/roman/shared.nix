{
  osConfig,
  lib,
  pkgs,
  ...
}:

{
  programs.fish.enable = true;

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
      auto_update = false;

      node = {
        path = lib.getExe pkgs.nodejs;
        npm_path = lib.getExe' pkgs.nodejs "npm";
      };

      lsp = {
        rust-analyzer = {
          binary = {
            path = lib.getExe' osConfig.rzhikharevich.rustToolchain "rust-analyzer";
          };
        };
        nil = {
          binary = {
            path = lib.getExe pkgs.nil;
          };
          initialization_options = {
            formatting.command = [ (lib.getExe pkgs.nixfmt) ];
          };
        };
        clangd = {
          binary = {
            path = lib.getExe' pkgs.clang-tools "clangd";
          };
        };
      };

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      show_edit_predictions = false;

      languages = {
        Nix = {
          tab_size = 2;
          language_servers = [
            "nil"
            "!nixd"
          ];
        };
      };
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      buffer_font_family = "JetBrains Mono";
      buffer_font_size = 15;
      ui_font_size = 16;
      theme = {
        mode = "system";
        light = "Dawnfox - opaque";
        dark = "Carbonfox - blurred";
      };
    };
    extensions = [
      "toml"
      "nix"
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      "nightfox"
    ];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "100.64.0.* microvm-*.local" = {
        extraOptions = {
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
        };
      };
      hetzner-ubuntu-main = {
        hostname = "157.90.114.181";
        user = "root";
      };
      nixodrome-boot = {
        hostname = "192.168.50.117";
        user = "root";
        extraOptions.HostKeyAlias = "nixodrome-boot";
      };
      nixodrome.hostname = "192.168.50.117";
      nixodrone.hostname = "192.168.50.118";
      nixform.hostname = "192.168.50.31";
    };
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.stateVersion = "25.11";
}
