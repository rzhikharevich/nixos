{
  lib,
  pkgs,
  osConfig,
  ...
}:

{
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
            nix.flake.autoArchive = true;
          };
        };
        clangd = {
          binary = {
            path = lib.getExe' pkgs.clang-tools "clangd";
          };
        };
        basedpyright = {
          binary = {
            path = lib.getExe' pkgs.basedpyright "basedpyright-langserver";
            arguments = [ "--stdio" ];
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
        Python = {
          language_servers = [
            "basedpyright"
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
      "basedpyright"
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      "nightfox"
    ];
  };
}
