{ pkgs, ... }:

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
