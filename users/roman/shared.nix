{ ... }:

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
    matchBlocks = {
      "100.64.0.*" = {
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

  home.stateVersion = "25.11";
}
