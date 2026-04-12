{
  config,
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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks =
      let
        nixodromeConfig = {
          forwardAgent = true;
        };
      in
      {
        "100.64.0.* microvm-*.local" = {
          extraOptions.StrictHostKeyChecking = "no";
          userKnownHostsFile = "/dev/null";
        };
        hetzner-ubuntu-main = {
          hostname = "157.90.114.181";
          user = "root";
        };
        nixodrome-boot = {
          hostname = "192.168.50.117";
          user = "root";
          extraOptions = {
            ConnectTimeout = "600";
            HostKeyAlias = "nixodrome-boot";
          };
        };
        nixodrome = {
          hostname = "192.168.50.117";
        }
        // nixodromeConfig;
        nixodrone = {
          hostname = "192.168.50.118";
        }
        // nixodromeConfig;
        nixform.hostname = "192.168.50.31";
      };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Roman Zhikharevich";
        email = "rzhikharevich@gmail.com";
      };

      core = {
        editor = "nano";
        pager = "less -R --mouse";
      };
    };
  };

  home.packages = [
    (pkgs.writePython3Script "cownix" {
      libraries = lib.optionals pkgs.stdenv.isLinux [ pkgs.python3Packages.asyncinotify ];
    } (builtins.readFile ../../scripts/cownix.py))
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  gtk.gtk4.theme = config.gtk.theme;

  home.stateVersion = "25.11";
}
