{
  config,
  ...
}:

{
  imports = [
    ./modules/hardened-services.nix
    ./modules/pam-no-fprint.nix
    ./modules/ssh-inhibit-suspend.nix
    ./modules/desktop.nix
    ./modules/kanata.nix
    ./users/greeter/default.nix
    ./users/roman/linux.nix
  ];

  boot.tmp.cleanOnBoot = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };

    optimise = {
      automatic = true;
      dates = "weekly";
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  users.users.root.openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
}
