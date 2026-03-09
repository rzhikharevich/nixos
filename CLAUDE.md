# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal NixOS/nix-darwin configuration. Currently a single NixOS host `nixform` (Minisforum V3, AMD). Flake-based, using NixOS unstable (25.11). Structured to support adding more hosts (including nix-darwin).

## Build Commands

```sh
nix build .#nixosConfigurations.nixform.config.system.build.toplevel # Build into ./result for verification.
```

## Architecture

**Entry point:** `flake.nix` defines host configurations via the `mkHost` helper.

**Structure:**
- `configuration.nix` — shared NixOS entry point; imports all modules and users
- `modules/` — shared NixOS modules (desktop, hardened services, globals, PAM, etc.)
- `hosts/` — host-specific config (boot, storage, networking, hardware)
- `users/` — per-user config; greeter has its own niri session, roman uses home-manager
- `lib/` — extends `nixpkgs.lib` with project helpers (polkit rules, service hardening)
- `overlays.nix` — custom overlay (`prerenderIcon`, `writePython3Script`, `roland`, `wvkbd`)

**Key design decisions:**
- SSH-key-only auth; keys centralized via `rzhikharevich.sshPubKeys` in `modules/globals.nix`.
- The greeter launches a dedicated niri session to host wlgreet, separate from the user's niri session.
- `lib/` extends `nixpkgs.lib` so helpers like `lib.mkPolkitAllow` are available everywhere. Derivation-producing helpers live in the overlay.
- `rzhikharevich.hardenedServices` applies a strict systemd hardening baseline; per-service overrides are merged on top.
- Service definitions stay in the same file as their related config (e.g. hyprlock service lives in `hyprlock.nix`).

## Code Style

- Indentation: 2-space tabs.
- Show, don't tell. Prefer clear code over verbose commentary.
- Code should be self-describing: use precise names for options, variables, and
  modules. Comments are for genuinely tricky logic — not restating what the code
  already says.
- Don't repeat yourself. Extract shared values into variables or custom options
  rather than duplicating them across modules.
- Follow the principle of least surprise. Options and module behavior should
  work the way a reasonable user would expect — no silent gotchas.
