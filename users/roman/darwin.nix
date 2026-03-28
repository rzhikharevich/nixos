{ config, pkgs, ... }:

{
  users.users.roman = {
    home = "/Users/roman";
    shell = pkgs.fish;
  };

  home-manager.users.roman = {
    imports = [
      ./shared.nix
    ];
  };
}
