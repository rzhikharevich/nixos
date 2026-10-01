# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal flake-based NixOS/nix-darwin configuration tracking `nixos-unstable`. The NixOS hosts are `nixform` (Minisforum V3, x86_64), `lagrange` (x86_64), and `nixodrome` (Apple Silicon, aarch64). The nix-darwin hosts are `secretive` and `tenserise` (both aarch64).

## Build Commands

```sh
nix build .#nixosConfigurations.HOSTNAME.config.system.build.toplevel
nix build .#darwinConfigurations.HOSTNAME.system # Run on macOS.
```

Substitute `lagrange` or `nixodrome` for the NixOS host, or `tenserise` for the Darwin host.

## Architecture

**Entry point:** `flake.nix` defines NixOS hosts with `mkHost` and nix-darwin hosts with `mkDarwinHost`. It assembles shared and platform-specific modules and overlays.

**Structure:**

- `configuration.nix` — settings shared by NixOS and nix-darwin; `linux.nix` and `darwin.nix` add platform-specific settings
- `modules/` — reusable system modules, including the Linux desktop, service hardening, and Linux/Darwin MicroVM adapters
- `hosts/` — host-specific boot, hardware, networking, and services
- `users/` — user and Home Manager modules; host-specific Home Manager imports are selected in `users/roman/shared.nix` and `users/greeter/default.nix`
- `lib/` — extends `nixpkgs.lib` with project helpers (polkit rules, service hardening)
- `packages.nix` and `packages/` — common package list and local package definitions
- `overlays.nix` — package overrides and derivation-producing helpers such as `prerenderIcon` and `writePython3Script`

**Key design decisions:**

- SSH-key-only auth; `rzhikharevich.sshPubKeys` is declared in `modules/globals.nix` and populated in `configuration.nix`.
- The greeter launches a dedicated niri session to host wlgreet, separate from the user's niri session.
- `rzhikharevich.hardenedServices` applies a strict systemd hardening baseline on NixOS; per-service overrides are merged on top.
- `modules/microvm.nix` defines the VMs shared by the Linux and Darwin host adapters.
- Service definitions stay in the same file as their related config (e.g. hyprlock service lives in `hyprlock.nix`).

## Code Style

- Indentation: 2 spaces.
- Show, don't tell. Prefer clear code over verbose commentary.
- Code should be self-describing: use precise names for options, variables, and
  modules. Comments are for genuinely tricky logic — not restating what the code
  already says.
- Don't repeat yourself. Extract shared values into variables or custom options
  rather than duplicating them across modules.
- Follow the principle of least surprise. Options and module behavior should
  work the way a reasonable user would expect — no silent gotchas.
