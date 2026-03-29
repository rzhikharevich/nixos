{
  lib,
  config,
  inputs,
  ...
}:

let
  inherit (inputs) microvm;
  inherit (microvmDefs) gateway vms;
  microvmDefs = import ./microvm.nix;
  microvmBase = import ./microvm-base.nix {
    sshPubKeys = config.rzhikharevich.sshPubKeys;
  };
in
{
  systemd.network = {
    enable = true;
    wait-online.enable = false;

    netdevs."20-vbr".netdevConfig = {
      Kind = "bridge";
      Name = "vbr";
    };

    networks."20-vbr" = {
      matchConfig.Name = "vbr";
      addresses = [ { Address = "${gateway}/24"; } ];
      networkConfig.ConfigureWithoutCarrier = true;
    };

    networks."21-vbr-tap" = {
      matchConfig.Name = "vm-*";
      networkConfig.Bridge = "vbr";
    };
  };

  services.resolved.enable = true;

  networking.nat = {
    enable = true;
    internalInterfaces = [ "vbr" ];
  };

  microvm.vms = lib.mapAttrs (name: vm: {
    autostart = false;
    config = {
      imports = [
        microvm.nixosModules.microvm
        microvmBase
      ];

      microvm = {
        inherit (vm) vcpu mem;
        hypervisor = "cloud-hypervisor";
        socket = "control.socket";
        vsock.cid = vm.vsockCid;
        cloud-hypervisor.extraArgs = [
          "--serial"
          "off"
          "--console"
          "tty"
        ];
        interfaces = [
          {
            type = "tap";
            id = "vm-${name}";
            mac = vm.mac;
          }
        ];
      };

      systemd.network.networks."10-lan" = {
        matchConfig.Name = "e*";
        addresses = [ { Address = vm.address; } ];
        routes = [ { Gateway = gateway; } ];
      };
    };
  }) vms;
}
