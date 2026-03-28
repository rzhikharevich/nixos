---
paths:
  - "**/*.nix"
  - "**/flake.lock"
---

# Nix Module Style

Conventions for writing clear, maintainable Nix flakes and modules.

## Expressions

- Use `if/else` over `mkMerge [ (mkIf A ...) (mkIf (!A) ...) ]` when the condition is a compile-time constant (e.g., `stdenv.isDarwin`).
- Don't string-interpolate (`"${x}"`) when a bare value suffices — derivations coerce to store paths automatically.
- Prefer `lib.all` / `lib.any` over materialising a filtered list and checking its length.

## Module Design

- Import shared definitions as real modules (`imports = [ ... ]`), not raw option sets (`mod.options // { ... }`). The latter silently drops any future `config`, `assertions`, or nested `imports`.
- Deduplicate module boilerplate with builder functions (e.g., `mkServiceOption`) rather than a shared module file imported differently by each consumer.
- Validate at the narrowest shared chokepoint so no consumer can bypass the check and no assertion is duplicated.
- Keep API surfaces consistent across platform modules — if NixOS uses `services.foo.enable`, Darwin and home-manager should too.

## Flake Conventions

- Use `nixpkgs.lib.genAttrs` over `flake-utils` for system iteration.
- Use `homeManagerModules` (not `homeModules`) as the flake output name.
- `legacyPackages` is the standard way to access nixpkgs — the name is misleading but not deprecated.
