# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal NixOS/nix-darwin configuration. Currently a single NixOS host `nixform` (Minisforum V3, AMD). Flake-based, using NixOS unstable (25.11). Structured to support adding more hosts (including nix-darwin).

## Build Commands

```sh
nix build .#nixosConfigurations.nixform.config.system.build.toplevel # Build into ./result for verification.
```

## Architecture

**Entry point:** `flake.nix` defines host configurations via the `mkHost` helper. Flake inputs:
- `nixpkgs` (nixos-unstable) — base packages
- `nixos-hardware` — Minisforum V3 hardware profile
- `home-manager` — per-user home configuration
- `stylix` — system-wide theming
- `niri-flake` — Niri Wayland compositor
- `fenix` — Rust toolchain management

`flake.nix` also defines `commonOverlays` (shared across all hosts) and `commonModules` (shared NixOS modules). Custom overlay helpers:
- `pkgs.prerenderIcon { name, src, size }` — rasterizes an SVG to PNG via `rsvg-convert`
- `pkgs.writePython3Script name source` — wraps `writers.writePython3Bin` with standard `flakeIgnore`

**Shared config:**
- `configuration.nix` — shared NixOS entry point (nix settings, locale, SSH, imports all modules and users)
- `modules/desktop.nix` — desktop environment (audio, polkit, keyring, fish, niri, packages, fonts, stylix)
- `modules/globals.nix` — custom NixOS options (e.g. `rzhikharevich.sshPubKeys`)
- `modules/hardened-services.nix` — `rzhikharevich.hardenedServices` option; applies default systemd hardening to declared services
- `modules/pam-no-fprint.nix` — defaults fingerprint auth to disabled in all PAM services
- `modules/ssh-inhibit-suspend.nix` — system service that inhibits suspend while SSH sessions are active

**Host-specific config:**
- `hosts/nixform/default.nix` — nixform hardware config (boot, storage, networking, power, udev)
- `hosts/nixform/hardware-configuration.nix` — hardware/filesystem config (LUKS-encrypted LVM, XFS root)

**Library:**
- `lib/default.nix` — extends `nixpkgs.lib` with project-specific helpers (polkit, hardening)
- `lib/polkit.nix` — `mkPolkitAllow`: generates polkit rules granting a set of actions to a user
- `lib/hardening.nix` — `mkHardenedUserService`: systemd hardening helpers for user services

**Users:**
- `users/greeter/default.nix` — greetd setup, greeter system user, polkit power rules
- `users/greeter/niri.nix` — greeter niri session (wlgreet, power menu, virtual keyboard, swayidle)
- `users/roman/default.nix` — user account definition + home-manager config (programs, styling, swayidle, wluma)
- `users/roman/niri.nix` — niri compositor settings + session services (wvkbd, swaybg, monitor power)
- `users/roman/waybar.nix` — waybar panel config and CSS
- `users/roman/swaync.nix` — notification center config
- `users/roman/hyprlock.nix` — lock screen config + hyprlock service
- `users/roman/firefox.nix` — Firefox privacy/extension config

**Key design decisions:**
- SSH-key-only authentication; no password-based login. Keys are centralized via the custom `rzhikharevich.sshPubKeys` option in `modules/globals.nix`.
- The greeter (`users/greeter/`) launches a dedicated niri session to host wlgreet, separate from the user's niri session.
- Home-manager is integrated as a NixOS module (not standalone), configured within `users/roman/default.nix`.
- Custom `lib/` extends `nixpkgs.lib` so helpers like `lib.mkPolkitAllow` are available in every module. Derivation-producing helpers live in the overlay (`pkgs.prerenderIcon`, `pkgs.writePython3Script`).
- Systemd services declared via `rzhikharevich.hardenedServices` receive a strict hardening baseline by default; per-service overrides are merged on top.
- Service definitions stay in the same file as their related config (e.g. hyprlock service lives in `hyprlock.nix`).
- Host-specific config (boot, storage, networking, hardware services) is separated from shared config to support adding new hosts via `mkHost`.

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
