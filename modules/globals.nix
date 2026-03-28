{ lib, pkgs, ... }:
{
  options.rzhikharevich = {
    sshPubKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of SSH public keys";
    };

    startUserUnit = lib.mkOption {
      type = lib.types.raw;
      default =
        if pkgs.stdenv.isDarwin
        then unit: "/bin/launchctl kickstart gui/$(/usr/bin/id -u)/${unit}"
        else unit: "${pkgs.systemd}/bin/systemctl --user start ${unit}";
    };

    stopUserUnit = lib.mkOption {
      type = lib.types.raw;
      default =
        if pkgs.stdenv.isDarwin
        then unit: "/bin/launchctl kill SIGTERM gui/$(/usr/bin/id -u)/${unit}"
        else unit: "${pkgs.systemd}/bin/systemctl --user stop ${unit}";
    };

    rustToolchain = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fenix.complete.withComponents [
        "cargo"
        "clippy"
        "rust-analyzer"
        "rust-src"
        "rustc"
        "rustfmt"
      ];
    };
  };
}
