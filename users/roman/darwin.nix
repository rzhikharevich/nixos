{
  inputs,
  pkgs,
  ...
}:

{
  users.users.roman = {
    home = "/Users/roman";
    shell = pkgs.fish;
  };

  home-manager.users.roman = {
    imports = [
      ./shared.nix
      inputs.revisor.homeManagerModules.default
    ];

    home.file.".hushlogin".text = "";
    home.sessionVariables.SSH_AUTH_SOCK = "/Users/roman/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";

    programs.ssh.matchBlocks."*".extraOptions.IdentityAgent =
      "/Users/roman/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";

    services.revisor = {
      enable = true;
      units = {
        skhd.script = ''
          exec ${pkgs.darwin_exec}/bin/darwin_exec -t daemon_interactive -d ${pkgs.skhd}/bin/skhd
        '';
        yabai.script = ''
          exec ${pkgs.darwin_exec}/bin/darwin_exec -t daemon_interactive -d ${pkgs.yabai}/bin/yabai
        '';
      };
    };
  };
}
