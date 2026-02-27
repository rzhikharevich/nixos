{ inputs, ... }:
inputs.nixpkgs.lib.extend (
  final: prev: import ./polkit.nix prev
)
