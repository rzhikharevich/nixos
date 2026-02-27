{ config, lib, pkgs, ... }:
let
  ssh-inhibit-suspend = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/rzhikharevich/nixos-artefacts/c1fcdd3f7974aaa73ae482f8f1c16ead6204d1dd/executables/ssh-inhibit-suspend";
    hash = "sha256-7cidbEPhP4DZGjuDhSkAEgle8Z8owxj3INYiBdQYoV8=";
    executable = true;
  };
in {
  users.users.ssh-inhibit-suspend = {
    isSystemUser = true;
    group = "ssh-inhibit-suspend";
  };
  users.groups.ssh-inhibit-suspend = {};

  security.polkit.extraConfig = lib.mkPolkitAllow "ssh-inhibit-suspend" [
    "org.freedesktop.login1.inhibit-block-sleep"
  ];

  rzhikharevich.hardenedServices.ssh-inhibit-suspend = {
    serviceConfig = {
      ExecStart = ssh-inhibit-suspend;
      Restart = "on-failure";
      CPUSchedulingPolicy = "idle";
      User = "ssh-inhibit-suspend";
      BindPaths = [ "/run/dbus/system_bus_socket" ];
    };
    wantedBy = [ "multi-user.target" ];
  };
}
