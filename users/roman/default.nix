{ config, pkgs, lib, ... }:

{
  users.users.roman = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
  };

  home-manager.users.roman = {
    imports = [ ./niri.nix ];
    programs.fish.enable = true;

    stylix = {
      image = pkgs.fetchurl {
        url = "https://github.com/rzhikharevich/nixos-artefacts/blob/main/wallpapers/GreatWave.jpg?raw=true";
        hash = "sha256-RKhIar3wMwo/5rWG5AdQbnOP4HX+C138Q5YeNY/acgY=";
      };
      polarity = "dark";
      icons = {
        enable = true;
        package = pkgs.colloid-icon-theme.override {
          colorVariants = ["grey"];
        };
        light = "Colloid";
        dark = "Colloid-Dark";
      };
    };

    home.stateVersion = "25.11";
  };
}
