{ pkgs }:
pkgs.writeShellScript "safe-suspend" ''
  if ${pkgs.coreutils}/bin/who | ${pkgs.gnugrep}/bin/grep -qE '\(.+\)$'; then
    exit 0
  fi
  exec ${pkgs.systemd}/bin/systemctl suspend
''
