# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal NixOS configuration for a system named `nixform`, targeting a Minisforum V3 (AMD). Flake-based, using NixOS unstable (25.11).

## Build Commands

```sh
sudo nixos-rebuild switch --flake .#nixform   # rebuild and switch
sudo nixos-rebuild build --flake .#nixform    # build without switching
nix flake update                              # update all flake inputs
nix flake update <input-name>                 # update a single input
```

## Architecture

**Entry point:** `flake.nix` defines a single NixOS configuration (`nixform`) composed from these flake inputs:
- `nixpkgs` (nixos-unstable) — base packages
- `nixos-hardware` — Minisforum V3 hardware profile
- `home-manager` — per-user home configuration
- `stylix` — system-wide theming
- `niri-flake` — Niri Wayland compositor

**Module layout:**
- `configuration.nix` — main system config (boot, networking, audio, packages, nix settings)
- `hardware-configuration.nix` — auto-generated hardware/filesystem config (LUKS-encrypted LVM, XFS root)
- `modules/globals.nix` — custom NixOS options (e.g. `rzhikharevich.sshPubKeys`)
- `modules/greeter.nix` — greetd + wlgreet login greeter running under niri
- `users/roman/default.nix` — user account definition + home-manager config (fish shell, stylix theming)
- `users/roman/niri.nix` — niri window manager settings (keyboard layouts, input devices, outputs)

**Key design decisions:**
- SSH-key-only authentication; no password-based login. Keys are centralized via the custom `rzhikharevich.sshPubKeys` option in `modules/globals.nix`.
- The greeter module launches a dedicated niri session to host wlgreet, separate from the user's niri session.
- Home-manager is integrated as a NixOS module (not standalone), configured within `users/roman/default.nix`.

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
