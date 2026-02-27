{ inputs, ... }:
inputs.nixpkgs.lib.extend (
  final: prev:
    (import ./polkit.nix prev) //
    (import ./hardening.nix prev)
)
