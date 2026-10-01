{
  lib,
  pkgs,
  ...
}:
{
  users.users.ssh-inhibit-suspend = {
    isSystemUser = true;
    group = "ssh-inhibit-suspend";
  };
  users.groups.ssh-inhibit-suspend = { };

  security.polkit.extraConfig = lib.mkPolkitAllow "ssh-inhibit-suspend" [
    "org.freedesktop.login1.inhibit-block-sleep"
  ];

  rzhikharevich.hardenedServices.ssh-inhibit-suspend = {
    serviceConfig = {
      ExecStart = lib.getExe pkgs.ssh-inhibit-suspend;
      Restart = "on-failure";
      CPUSchedulingPolicy = "idle";
      User = "ssh-inhibit-suspend";
      BindPaths = [ "/run/dbus/system_bus_socket" ];
    };
    wantedBy = [ "multi-user.target" ];
  };
}
