#!/bin/sh

set -euo pipefail

nix flake metadata --json \
    | jq '.locks.nodes.root.inputs | keys[]' \
    | grep -v '^"nixos-apple-silicon"$' \
    | grep -v '^"nixpkgs-darwin-ax"$' \
    | xargs nix flake update
