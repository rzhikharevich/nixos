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

  users.users.roman.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF2fP9JIo11WvBE8F0KKB3l8W/PU/54iPcH2liX0dAle root@tenserise"
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

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
  ];

  system.stateVersion = "25.11";
}
