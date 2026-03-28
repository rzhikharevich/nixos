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
    matchBlocks."100.64.0.*" = {
      extraOptions = {
        StrictHostKeyChecking = "no";
        UserKnownHostsFile = "/dev/null";
      };
    };
  };

  home.stateVersion = "25.11";
}
