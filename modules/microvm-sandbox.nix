{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;
  apps = config.rzhikharevich.microvmSandboxes;

  # Each TAP lives in its own network namespace, so every sandbox can use
  # the same point-to-point subnet and guest MAC without host routes.
  proxyAddress = "192.0.2.1";
  guestAddress = "192.0.2.2";
  guestMac = "02:00:00:00:00:01";
  internetMac = "02:00:00:00:00:02";
  internetSocket = name: "/run/microvm-internet-${name}/net.sock";
  tapName = name: "${builtins.substring 0 11 name}-tap";

  requireMount = path: {
    RequiresMountsFor = path;
    AssertPathIsMountPoint = path;
  };
in
{
  options.rzhikharevich.microvmSandboxes = mkOption {
    description = "Web applications served from private MicroVMs through host Unix sockets.";
    default = { };
    type = types.attrsOf (
      types.submodule (
        { name, ... }: {
          options = {
            port = mkOption {
              type = types.port;
              description = "TCP port the application listens on inside the guest.";
            };
            allowInternet = lib.mkEnableOption "outbound public IPv4 access from the sandbox";
            service = mkOption {
              type = types.str;
              default = name;
              description = "Guest systemd service name to apply the network and mount restrictions to.";
            };
            guestConfig = mkOption {
              type = types.deferredModule;
              description = "NixOS module configuring the guest application, resources and state version.";
            };
            dataDir = mkOption {
              type = types.nullOr types.externalPath;
              default = null;
              description = "Optional host mount point to share with the guest at the same path using virtiofs.";
            };
            dataDirRequires = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Host units that must run before virtiofsd can export the data mount.";
            };
            socketGroup = mkOption {
              type = types.str;
              default = config.services.nginx.group;
              defaultText = lib.literalExpression "config.services.nginx.group";
              description = "Host group allowed to connect to the application socket.";
            };
            socketPath = mkOption {
              type = types.str;
              readOnly = true;
              default = "/run/${name}/http.sock";
              description = "Host Unix socket for the reverse proxy to connect to.";
            };
          };
        }
      )
    );
  };

  config = {
    microvm.vms = lib.mapAttrs (name: app: {
      config = {
        imports = [ app.guestConfig ];
        microvm = {
          hypervisor = "cloud-hypervisor";
          socket = "control.socket";
          interfaces = [
            {
              type = "tap";
              id = tapName name;
              mac = guestMac;
            }
          ];
          cloud-hypervisor.extraArgs = lib.optionals app.allowInternet [
            "--net"
            "vhost_user=true,mac=${internetMac},socket=${internetSocket name}"
          ];
          shares = [
            {
              proto = "virtiofs";
              tag = "store";
              source = "/nix/store";
              mountPoint = "/nix/store";
              readOnly = true;
            }
          ]
          ++ lib.optional (app.dataDir != null) {
            proto = "virtiofs";
            tag = "data";
            source = app.dataDir;
            mountPoint = app.dataDir;
          };
        };
        fileSystems."/nix/store".options = [ "ro" ];
        networking.useDHCP = false;
        networking.firewall.allowedTCPPorts = [ app.port ];
        systemd.network.networks."10-${name}" = {
          matchConfig.MACAddress = guestMac;
          address = [ "${guestAddress}/30" ];
          networkConfig = {
            LinkLocalAddressing = false;
            IPv6AcceptRA = false;
          };
        };
        systemd.network.networks."20-internet" = lib.mkIf app.allowInternet {
          matchConfig.MACAddress = internetMac;
          networkConfig = {
            DHCP = "ipv4";
            LinkLocalAddressing = false;
            IPv6AcceptRA = false;
          };
        };
        systemd.services.${app.service} = {
          unitConfig = lib.optionalAttrs (app.dataDir != null) (requireMount app.dataDir);
          serviceConfig = {
            IPAddressAllow = [ proxyAddress ];
            IPAddressDeny = lib.mkIf (!app.allowInternet) "any";
          };
        };
      };
    }) apps;

    systemd.services = lib.mkMerge (
      lib.mapAttrsToList (
        name: app:
        let
          tapService = "microvm-tap-interfaces@${name}";
          tapUnit = "${tapService}.service";
        in
        {
          # The upstream TAP oneshot stays active and holds the private namespace.
          ${tapService}.serviceConfig = {
            PrivateNetwork = true;
            ExecStartPost = "${pkgs.iproute2}/bin/ip address replace ${proxyAddress}/30 dev ${tapName name}";
          };
          "microvm@${name}" = {
            unitConfig.JoinsNamespaceOf = tapUnit;
            serviceConfig.PrivateNetwork = true;
            requires = lib.optional app.allowInternet "microvm-internet-${name}.service";
            after = lib.optional app.allowInternet "microvm-internet-${name}.service";
          };
          "microvm-internet-${name}" = lib.mkIf app.allowInternet {
            description = "Outbound internet for MicroVM ${name}";
            partOf = [ "microvm@${name}.service" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            serviceConfig = {
              Type = "forking";
              # An automatic restart propagates to the VM, which reconnects to the new socket.
              Restart = "always";
              User = "microvm";
              RuntimeDirectory = "microvm-internet-${name}";
              RuntimeDirectoryMode = "0700";
              PIDFile = "/run/microvm-internet-${name}/passt.pid";
              ExecStart = lib.concatStringsSep " " [
                "${lib.getExe pkgs.passt} --vhost-user --socket ${internetSocket name}"
                "--pid /run/microvm-internet-${name}/passt.pid --repair-path none"
                "--ipv4-only --address 10.0.2.15/24 --gateway 10.0.2.2"
                "--dns 1.1.1.1 --dns 9.9.9.9 --no-dhcp-search"
                "--map-host-loopback none --tcp-ports none --udp-ports none"
              ];
              # Enforce the address policy on the host sockets opened for the guest.
              RestrictNetworkInterfaces = "~lo";
              IPAddressDeny = [
                "0.0.0.0/8"
                "10.0.0.0/8"
                "100.64.0.0/10"
                "localhost"
                "link-local"
                "172.16.0.0/12"
                "192.0.0.0/24"
                "192.0.2.0/24"
                "192.168.0.0/16"
                "198.18.0.0/15"
                "198.51.100.0/24"
                "203.0.113.0/24"
                "224.0.0.0/3"
                "::/0"
              ];
            };
          };
          "${name}-proxy" = {
            bindsTo = [ tapUnit ];
            after = [ tapUnit ];
            unitConfig.JoinsNamespaceOf = tapUnit;
            serviceConfig = {
              PrivateNetwork = true;
              DynamicUser = true;
              ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd ${guestAddress}:${toString app.port}";
            };
          };
          "microvm-virtiofsd@${name}" = lib.mkIf (app.dataDir != null) {
            requires = app.dataDirRequires;
            after = app.dataDirRequires;
            unitConfig = requireMount app.dataDir;
          };
        }
      ) apps
    );

    systemd.sockets = lib.mapAttrs' (
      name: app:
      lib.nameValuePair "${name}-proxy" {
        wantedBy = [ "microvm@${name}.service" ];
        partOf = [ "microvm@${name}.service" ];
        socketConfig = {
          ListenStream = app.socketPath;
          SocketGroup = app.socketGroup;
          SocketMode = "0660";
          RemoveOnStop = true;
        };
      }
    ) apps;
  };
}
