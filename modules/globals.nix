{ lib, pkgs, ... }:
{
  options.rzhikharevich = {
    sshPubKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of SSH public keys";
    };

    # Might want to override in some configs eventually.
    startUserUnit = lib.mkOption {
      type = lib.types.raw;
      default = unit: "${pkgs.systemd}/bin/systemctl --user start ${unit}";
    };

    stopUserUnit = lib.mkOption {
      type = lib.types.raw;
      default = unit: "${pkgs.systemd}/bin/systemctl --user stop ${unit}";
    };
  };
}
