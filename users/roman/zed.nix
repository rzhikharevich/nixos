{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  mkRunInDevShell =
    pkg: bin:
    pkgs.writeShellScript "run-in-devshell" ''
      ${lib.getExe' pkgs.nix "nix"} develop -c ${bin} "$@" || exec ${lib.getExe' pkg bin} "$@"
    '';
in
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
        asm-lsp = {
          binary = {
            path = lib.getExe' pkgs.asm-lsp "asm-lsp";
          };
        };
        rust-analyzer = {
          binary = {
            path = mkRunInDevShell osConfig.rzhikharevich.rustToolchain "rust-analyzer";
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
            path = lib.rzMatchDefault osConfig.networking.hostName [
              [
                "tenserise"
                "/usr/bin/clangd"
              ]
            ] { default = lib.getExe' pkgs.clang-tools "clangd"; };
          };
        };
        basedpyright = {
          binary = {
            path = mkRunInDevShell pkgs.basedpyright "basedpyright-langserver";
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
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
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
      "assembly"
      "toml"
      "nix"
      "basedpyright"
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      "nightfox"
    ];
  };
}
