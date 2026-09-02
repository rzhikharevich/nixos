{
  config,
  pkgs,
  lib,
  isLinux,
  isDarwin,
  ...
}:

let
  nanoConfig = ''
    set autoindent
    set linenumbers
    set tabstospaces
    set tabsize 4
    set softwrap
    set minibar
    set stateflags
    set nohelp
    set guidestripe 100
    set magic
    set constantshow
    set indicator
    set historylog
    set mouse
    set smarthome
  '';
in

{
  imports = [
    ./modules/globals.nix
  ];

  config = lib.mkMerge [
    {
      rzhikharevich.sshPubKeys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIbfIla3NlPdru/+T7qvipOiI3ZcGBhrI6dWhZn6YFnnBuVfbeqoe7k/DAgqTQb9MLlRNIwXJHb/90cU/+7xXV8= sec-one@secretive"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDgxhKulUZwvKQ8HvCHDEiGLX29UzUdr+Lor55EdcKzE roman@nixform"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBwxpC2XM9Ialnbm51C5UCIW2ih9+tTBzkjWUc2Fv9ORFw4XCeTLSwHLQt+hLD5fm8E5lnF9QxV1Jt8/851jIyk= ShellFish@iPhone-Enclave"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLZO8MGZlwy/qapHY8/BcqImx8H/INpnUiY8mIRPu6g5T8BC6NMUbWToyM3P4Jz4hHMaXKEUlZK6qewrWrEcDPA= roman@tenserise"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEKX3/69CRZsWETBR+i81z3gu0OzDN7jGBfU87efRYr1 roman@lagrange"
      ];

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "pipe-operators"
        ];
        download-buffer-size = 1024 * 1048576;
        allowed-users = [
          "roman"
          "greeter"
        ];
        trusted-users = [ "roman" ];
      };

      nix.gc.options = "--delete-older-than 30d";

      nixpkgs.config.allowUnfree = true;

      time.timeZone = "Europe/London";

      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;
      };

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set fish_greeting
          alias ssh-local "ssh -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null"
        ''
        + (
          if isLinux then
            ''
              if test "$RZ_CLIENT_PLATFORM" = "darwin"
                function fish_in_macos_terminal
                  true
                end
              end
            ''
          else
            ''
              set -x RZ_CLIENT_PLATFORM darwin
            ''
        );
      };

      services.openssh = {
        enable = true;
      }
      // lib.optionalAttrs isLinux {
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          AcceptEnv = [ "RZ_CLIENT_PLATFORM" ];
        };
      }
      // lib.optionalAttrs isDarwin {
        extraConfig = ''
          PasswordAuthentication no
          KbdInteractiveAuthentication no
        '';
      };
    }

    (lib.optionalAttrs isLinux {
      programs.nano.nanorc = nanoConfig;
    })

    (lib.mkIf isDarwin {
      environment.etc."nanorc".text = nanoConfig;
    })
  ];
}
