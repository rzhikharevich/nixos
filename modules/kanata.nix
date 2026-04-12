{
  pkgs,
  lib,
  isLinux,
  ...
}:
if isLinux then
  {
    services.udev.extraRules = ''
      ATTRS{name}=="kanata", SUBSYSTEM=="input", TAG+="seat", ENV{ID_SEAT}="seat0"
    '';

    systemd.services.kanata-default.serviceConfig.ExecStartPre = [
      "+${pkgs.acl}/bin/setfacl -m g::rw /dev/uinput"
    ];

    services.kanata = {
      enable = true;
      keyboards.default = {
        devices = [ ];
        extraDefCfg = ''
          process-unmapped-keys yes
          linux-device-detect-mode keyboard-only
          linux-output-device-bus-type USB
        '';
        config = ''
          (defsrc
            caps i j k l v)

          (defalias
            nav (layer-toggle navigation))

          (deflayer default
            @nav i j k l v)

          (deflayer navigation
            _ up left down right caps)
        '';
      };
    };
  }
else
  let
    karabinerDriver = pkgs.kanata.passthru.darwinDriver;
    karabinerAppDir = "/Applications/.Nix-Karabiner";
    managerApp = "${karabinerAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager";
  in
  {
    # DriverKit extensions must reside in /Applications, not as symlinks.
    system.activationScripts.preActivation.text = ''
      set -euo pipefail
      mkdir -p /var/db/nix-darwin

      cleanup() {
        rm -rf ${karabinerAppDir}/tmp
      }
      trap cleanup EXIT
      cleanup

      old_src=$(cat /var/db/nix-darwin/karabiner-driver-drv 2>/dev/null || true)
      if [ "$old_src" != ${karabinerDriver} ]; then
        echo "Replacing Karabiner driver..."

        mkdir -p ${karabinerAppDir}/tmp

        /usr/bin/ditto ${karabinerDriver}/Applications/.Karabiner-VirtualHIDDevice-Manager.app \
          ${karabinerAppDir}/tmp/.incoming.app

        if [ -e ${karabinerAppDir}/.Karabiner-VirtualHIDDevice-Manager.app ]; then
          mv ${karabinerAppDir}/.Karabiner-VirtualHIDDevice-Manager.app ${karabinerAppDir}/tmp/.outgoing.app
        fi

        mv ${karabinerAppDir}/tmp/.incoming.app ${karabinerAppDir}/.Karabiner-VirtualHIDDevice-Manager.app
        echo ${karabinerDriver} > /var/db/nix-darwin/karabiner-driver-drv
      else
        echo "Karabiner driver up to date."
      fi
    '';

    launchd.daemons.Karabiner-VirtualHIDDevice-Daemon = {
      command = ''"${karabinerDriver}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"'';
      serviceConfig = {
        ProcessType = "Interactive";
        Label = "org.pqrs.Karabiner-VirtualHIDDevice-Daemon";
        KeepAlive = true;
      };
    };

    launchd.daemons.kanata = {
      script = ''
        set -e
        ${managerApp} activate
        exec ${pkgs.darwin_exec}/bin/darwin_exec -t daemon_interactive -d -- \
          ${lib.getExe pkgs.kanata} --nodelay --no-wait --quiet --cfg ${
            pkgs.writeTextFile {
              name = "kanata.cfg";
              text = ''
                (deflocalkeys-macos § 86)

                (defsrc
                  f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12
                  §
                  caps i j k l v d c 1 2 3 4 5 spc
                  `)

                (defalias
                  nav (layer-toggle custom))

                (deflayer default
                  🔅 🔆 ✗ ✗ ✗ ✗ ◀◀ ▶⏸ ▶▶ 🔇 🔉 🔊
                  `
                  @nav i j k l v d c 1 2 3 4 5 spc
                  §)

                (deflayer custom
                  f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12
                  `
                  _ up left down right caps C-d C-c C-1 C-2 C-3 C-4 C-5 C-spc
                  §)
              '';
            }
          }
      '';
      serviceConfig = {
        ProcessType = "Interactive";
        KeepAlive = true;
        RunAtLoad = true;
      };
    };
  }
