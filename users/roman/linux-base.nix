{
  config,
  pkgs,
  ...
}:

{
  users.users.roman = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "input"
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
