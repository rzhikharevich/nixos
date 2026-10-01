{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    (inputs.self + /modules/ssh-inhibit-suspend.nix)
  ];

  rzhikharevich.touchDisplay = "eDP-1";

  networking.hostName = "nixform";

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
  ];

  system.stateVersion = "25.11";
}
