{ config, lib, pkgs, ... }:
{
  systemd.user.timers = {
    build-job-nixos = {
      Unit = {
        Description = "nixos build job";
      };
      Timer = {
        OnCalendar = "Saturday *-*-* 03:00:00";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services = {
    build-job-nixos = {
      Unit.Description = "nixos build job";
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "build-job-nixos" ''
          set -euxo pipefail

          git() {
            GIT_SSH=${pkgs.openssh}/bin/ssh ${pkgs.git}/bin/git "$@"
          }

          if [ -d nixos ]; then
            cd nixos
            git checkout HEAD flake.lock
            git pull
          else
            git clone git@github.com:rzhikharevich/nixos
            cd nixos
          fi

          nix() {
            PATH=${pkgs.git}/bin:$PATH ${pkgs.nix}/bin/nix "$@"
          }

          ${pkgs.nix}/bin/nix-store --add-fixed sha256 --recursive /boot/asahi

          nix flake update
          nix build .#nixosConfigurations.nixodrome.config.system.build.toplevel
        '';
        WorkingDirectory = "%h/Development/Jobs/nixos";
        Restart = false;
        RemainAfterExit = true;
      };
    };
  };
}
