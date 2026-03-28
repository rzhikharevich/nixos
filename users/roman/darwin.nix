{ pkgs, ... }:

{
  users.users.roman = {
    home = "/Users/roman";
    shell = pkgs.fish;
  };

  home-manager.users.roman = {
    imports = [
      ./shared.nix
    ];

    home.file.".hushlogin".text = "";
    home.sessionVariables.SSH_AUTH_SOCK = "/Users/roman/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";

    programs.ssh.matchBlocks."*".extraOptions.IdentityAgent =
      "/Users/roman/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
  };
}
