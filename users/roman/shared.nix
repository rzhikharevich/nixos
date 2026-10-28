{
  osConfig,
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
    [
      "lagrange"
      [ (import ./hosts/lagrange/default.nix) ]
    ]
    [
      "nixform"
      [ (import ./hosts/nixform/default.nix) ]
    ]
    [
      "tenserise"
      [ (import ./hosts/tenserise/default.nix) ]
    ]
  ] { default = [ ]; };

  programs.fish.enable = true;

  programs.claude-code = {
    enable = true;
    rules = {
      nix-modules = ./claude/rules/nix-modules.md;
      rust-code-style = ./claude/rules/rust-code-style.md;
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
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
        HostName = "100.102.126.120";
        ForwardAgent = true;
      };
      nixodrome-wlan = {
        HostName = "192.168.50.118";
        ForwardAgent = true;
      };
      nixform.HostName = "100.107.69.77";
      panther-boot = {
        HostName = "192.168.50.244";
        User = "root";
        ConnectTimeout = 600;
        HostKeyAlias = "panther-boot";
      };
      panther = {
        HostName = "100.83.29.93";
        ForwardAgent = true;
      };
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
        pager = lib.getExe pkgs.delta;
      };

      interactive.diffFilter = "${lib.getExe pkgs.delta} --color-only";

      delta = {
        navigate = true;
        conflictStyle = "zdiff3";
        line-numbers = true;
      };
    };
  };

  home.packages = [
    (pkgs.writePython3Script "cownix" {
      libraries = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.python3Packages.asyncinotify ];
    } (builtins.readFile ../../scripts/cownix.py))
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    DELTA_PAGER = "less -R --mouse";
  };

  home.pointerCursor.enable = lib.mkDefault false;
  home.stateVersion = "25.11";
}
