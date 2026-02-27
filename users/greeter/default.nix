{ lib, pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.niri}/bin/niri";
      user = "greeter";
    };
  };

  security.polkit.extraConfig = lib.mkPolkitAllow "greeter" [
    "org.freedesktop.login1.power-off"
    "org.freedesktop.login1.power-off-multiple-sessions"
    "org.freedesktop.login1.power-off-ignore-inhibit"
    "org.freedesktop.login1.reboot"
    "org.freedesktop.login1.reboot-multiple-sessions"
    "org.freedesktop.login1.reboot-ignore-inhibit"
  ];

  security.pam.services.greetd.enableGnomeKeyring = true;

  users.users.greeter = {
    isSystemUser = true;
    createHome = true;
    home = "/home/greeter";
  };

  home-manager.users.greeter = {
    imports = [ ./niri.nix ];

    home.stateVersion = "25.11";
  };
}
