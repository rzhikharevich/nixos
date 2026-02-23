{ config, pkgs, lib, ... }:
let
  safeSuspend = import ../../scripts/safe-suspend.nix { inherit pkgs; };
in
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
    programs.foot.enable = true;
    programs.swaylock.enable = true;

    services.swayidle = {
      enable = true;
      events = {
        before-sleep = "${pkgs.niri} msg action power-off-monitors";
        after-resume = "${pkgs.niri} msg action power-on-monitors";
      };
      timeouts = [
        { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock && ${safeSuspend}"; }
      ];
    };

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
