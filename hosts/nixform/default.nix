{
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./boot.nix
    (inputs.self + /modules/ssh-inhibit-suspend.nix)
  ];

  networking = {
    hostName = "nixform";
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

  security.pam.services.hyprlock = { };

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

  system.stateVersion = "25.11";
}
