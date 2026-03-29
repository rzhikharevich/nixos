{ callPackage, ... }:

{
  vmnet-broker = callPackage ./vmnet-broker.nix { };
  vmnet-helper = callPackage ./vmnet-helper.nix { };
}
