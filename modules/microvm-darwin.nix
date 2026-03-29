{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  inherit (inputs) microvm;
  inherit (microvmDefs) vms;
  microvmDefs = import ./microvm.nix;
  microvmBase = import ./microvm-base.nix {
    sshPubKeys = config.rzhikharevich.sshPubKeys;
  };

  runners = lib.mapAttrs (
    name: vm:
    (lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        microvm.nixosModules.microvm
        microvmBase
        {
          networking.hostName = name;

          microvm = {
            inherit (vm) vcpu mem;
            hypervisor = "vfkit";
            vmHostPackages = pkgs;
            socket = "control.socket";
            interfaces = [ ];
            vfkit.extraArgs = [
              "--device"
              "virtio-net,fd=4,mac=${vm.mac}"
            ];
          };

          systemd.network.networks."10-lan" = {
            matchConfig.Name = "e*";
            DHCP = "ipv4";
            dhcpV4Config.ClientIdentifier = "mac";
          };
        }
      ];
    }).config.microvm.declaredRunner
  ) vms;
in
{
  launchd.daemons.vmnet-broker = {
    command = "${pkgs.vmnet-broker}/bin/vmnet-broker";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      MachServices."com.github.nirs.vmnet-broker" = true;
      EnableTransactions = true;
    };
  };

  launchd.user.agents = lib.mapAttrs' (
    name: runner:
    lib.nameValuePair "microvm-${name}" {
      environment.HOME = config.users.users.${config.system.primaryUser}.home;
      script = ''
        dir="$HOME/.local/state/microvms/${name}"
        mkdir -p "$dir"
        cd "$dir"
        ln -sfn ${runner} current
        exec script -q /dev/null ${pkgs.vmnet-helper}/bin/vmnet-client \
          --network shared --unprivileged -- \
          ${runner}/bin/microvm-run
      '';
      serviceConfig = {
        KeepAlive = false;
        RunAtLoad = false;
        ExitTimeOut = 30;
      };
    }
  ) runners;
}
