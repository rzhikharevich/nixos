{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./boot.nix
  ];

  users.users.roman.uid = 1001;

  networking.hostName = "lagrange";

  environment.systemPackages = with pkgs; [
    inputs.hauntedcupofdotfiles.packages.x86_64-linux.dungeondraft
    ungoogled-chromium
  ];

  fonts.fontconfig = {
    subpixel.lcdfilter = "none";
    hinting = {
      enable = true;
      style = "medium";
    };
  };

  system.stateVersion = "26.05";
}
