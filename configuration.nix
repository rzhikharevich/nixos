{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./modules/globals.nix
    ./modules/hardened-services.nix
    ./modules/pam-no-fprint.nix
    ./modules/ssh-inhibit-suspend.nix
    ./modules/desktop.nix
    ./users/greeter/default.nix
    ./users/roman/default.nix
  ];

  rzhikharevich.sshPubKeys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIbfIla3NlPdru/+T7qvipOiI3ZcGBhrI6dWhZn6YFnnBuVfbeqoe7k/DAgqTQb9MLlRNIwXJHb/90cU/+7xXV8= sec-one@secretive"
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      download-buffer-size = 1024 * 1048576;
      # extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
      trusted-users = [ "@wheel" ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    optimise = {
      automatic = true;
      dates = "weekly";
    };
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
}
