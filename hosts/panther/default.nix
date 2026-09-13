{
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    (inputs.self + /modules/tailscale.nix)
  ];

  networking = {
    hostId = "b0d86da2";
    hostName = "panther";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      unmanaged = [
        "interface-name:vbr"
        "interface-name:vm-*"
      ];
    };
    wireless.iwd = {
      enable = true;
      settings = {
        Settings.AutoConnect = true;
      };
    };
    useDHCP = false;
  };

  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--autopilot" ];
  };

  system.stateVersion = "26.05";
}
