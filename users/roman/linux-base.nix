{
  config,
  pkgs,
  ...
}:

{
  users.users.roman = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = config.rzhikharevich.sshPubKeys;
  };

  home-manager.users.roman = {
    imports = [
      ./shared.nix
    ];
  };
}
