{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./boot.nix
#    (inputs.self + /modules/ssh-inhibit-suspend.nix)
    (inputs.self + /modules/tailscale.nix)
  ];

  networking = {
    hostName = "lagrange";
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

  services.upower = {
    enable = true;
    criticalPowerAction = "Hibernate";
    noPollBatteries = true;
  };

  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--autopower" ];
  };

  programs.fuse.enable = true;

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
  ];

  system.stateVersion = "26.05";
}
