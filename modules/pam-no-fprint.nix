{ lib, ... }:
{
  options.security.pam.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        config.fprintAuth = lib.mkDefault false;
      }
    );
  };
}
