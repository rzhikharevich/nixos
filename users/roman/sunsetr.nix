{ pkgs, ... }:
{
  home.packages = [ pkgs.sunsetr ];

  systemd.user.services.sunsetr = {
    Unit = {
      Description = "Automatic blue light filter";
      Documentation = "https://github.com/psi4j/sunsetr";
      PartOf = [ "graphical-session.target" ];
      Requires = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = [ "WAYLAND_DISPLAY" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.sunsetr}/bin/sunsetr";
      Restart = "on-failure";
      RestartSec = 30;
      Slice = "background.slice";
      ConfigurationDirectory = "sunsetr";
      ConfigurationDirectoryMode = "0700";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
