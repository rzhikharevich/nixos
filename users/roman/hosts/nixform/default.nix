{ pkgs, ... }:
{
  stylix = {
    image = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/rzhikharevich/nixos-artefacts/f6e480efbf530c6eeeba2d361a7afab7ac322a6b/wallpapers/GreatWave.jpg";
      hash = "sha256-RKhIar3wMwo/5rWG5AdQbnOP4HX+C138Q5YeNY/acgY=";
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };

  programs.niri.settings = {
    outputs = {
      "eDP-1" = {
        scale = 1.5;
        variable-refresh-rate = true;
      };
    };
  };
}
