{ pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.niri}/bin/niri";
      user = "greeter";
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
           action.id == "org.freedesktop.login1.power-off-ignore-inhibit" ||
           action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
           action.id == "org.freedesktop.login1.reboot-ignore-inhibit") &&
          subject.user == "greeter") {
        return polkit.Result.YES;
      }
    });
  '';

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
