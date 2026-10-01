{ lib, ... }:
{
  environment.etc."lvm/lvm.conf".text = lib.mkForce ''
    devices {
      issue_discards = 1
    }
  '';
}
