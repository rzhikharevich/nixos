{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = lib.rzMatchDefault osConfig.networking.hostName [
    [
      "nixodrome"
      [ (import ./hosts/nixodrome/default.nix) ]
    ]
  ] { default = [ ]; };

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
    settings =
      let
        nixodromeConfig = {
          ForwardAgent = true;
        };
      in
      {
        "*".SendEnv = "RZ_CLIENT_PLATFORM";
        "100.64.0.* microvm-*.local" = {
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
        };
        hetzner-ubuntu-main = {
          HostName = "157.90.114.181";
          User = "root";
        };
        nixodrome-boot = {
          HostName = "192.168.50.117";
          User = "root";
          ConnectTimeout = 600;
          HostKeyAlias = "nixodrome-boot";
        };
        nixodrome = {
          HostName = "192.168.50.117";
        }
        // nixodromeConfig;
        nixodrone = {
          HostName = "192.168.50.118";
        }
        // nixodromeConfig;
        nixform.HostName = "192.168.50.31";
      };
  };

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";

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
