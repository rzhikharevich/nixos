#!/bin/sh

set -euo pipefail

nix flake metadata --json \
    | jq '.locks.nodes.root.inputs | keys[]' \
    | grep -v '^"nixos-apple-silicon"$' \
    | xargs nix flake update
