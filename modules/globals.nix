{ lib, ... }:
{
  options.rzhikharevich.sshPubKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "List of SSH public keys";
  };
}
