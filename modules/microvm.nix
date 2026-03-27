{
  pkgs,
  config,
  inputs,
  ...
}:

let
  inherit (inputs) microvm;
in
{
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;

  systemd.network.netdevs."20-vbr".netdevConfig = {
    Kind = "bridge";
    Name = "vbr";
  };

  services.resolved.enable = true;

  systemd.network.networks."20-vbr" = {
    matchConfig.Name = "vbr";
    addresses = [ { Address = "100.64.0.1/24"; } ];
    networkConfig = {
      ConfigureWithoutCarrier = true;
    };
  };

  systemd.network.networks."21-vbr-tap" = {
    matchConfig.Name = "vm-*";
    networkConfig.Bridge = "vbr";
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "vbr" ];
  };

  systemd.services."microvm@monaco".serviceConfig.ExecStart =
    let
      stateDir = "/var/lib/microvms";
      vsockNotifyProxy = pkgs.writePython3Script "vsock-notify-proxy" { doCheck = false; } ''
        import asyncio
        import os
        import socket

        notify_socket = os.environ["NOTIFY_SOCKET"]
        notify = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        log_file = open("/tmp/vsock_proxy.log", "w")

        async def handle(reader, writer):
            chunks = []
            while True:
                chunk = await reader.read(65536)
                if not chunk:
                    break
                chunks.append(chunk)
                if chunk.endswith(b"\n"):
                    break
            writer.close()
            data = b"".join(chunks)
            if data:
                print("data:", repr(data), file=log_file, flush=True)
                notify.sendto(data, notify_socket)

        async def main():
            server = await asyncio.start_unix_server(handle, path="notify.vsock_8888")
            await server.serve_forever()

        asyncio.run(main())
      '';
      wrapper = pkgs.writeShellScript "microvm-monaco-run" ''
        script=$(${pkgs.coreutils}/bin/mktemp)
        ${pkgs.gnused}/bin/sed \
          '/socat.*UNIX-LISTEN.*vsock.*fork/c\  ${vsockNotifyProxy}/bin/vsock-notify-proxy &' \
          ${stateDir}/monaco/current/bin/microvm-run > "$script"
        exec ${pkgs.bash}/bin/bash "$script"
      '';
    in
    pkgs.lib.mkForce [
      ""
      (toString wrapper)
    ];

  microvm.vms.monaco = {
    autostart = false;
    config = {
      imports = [
        microvm.nixosModules.microvm
        ./microvm-base.nix
      ];

      microvm = {
        hypervisor = "cloud-hypervisor";
        #hypervisor = "qemu";
        vcpu = 4;
        mem = 4096;
        socket = "control.socket";
        vsock.cid = 3;
        cloud-hypervisor.extraArgs = [
          "--serial"
          "off"
          "--console"
          "tty"
        ];
        interfaces = [
          {
            type = "tap";
            id = "vm-monaco";
            mac = "02:00:00:00:00:01";
          }
        ];
        shares = [
          {
            proto = "virtiofs";
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }
        ];
      };

      services.openssh = {
        enable = true;
        hostKeys = [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };
      users.users.root.openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;

      systemd.network.networks."10-lan" = {
        matchConfig.Name = "e*";
        addresses = [ { Address = "100.64.0.2/24"; } ];
        routes = [ { Gateway = "100.64.0.1"; } ];
      };
      networking.nameservers = [
        "8.8.8.8"
        "1.1.1.1"
      ];

      system.stateVersion = "25.11";
    };
  };
}
