#!/usr/bin/env python3

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "cownix"
STATE_FILE = STATE_DIR / "cownix.json"


def main():
    args = parse_args()
    args.func(args.path)


def parse_args():
    parser = argparse.ArgumentParser(description="Copy and restore Nix store symlinks")
    subparsers = parser.add_subparsers(required=True)

    write_parser = subparsers.add_parser(
        "write", help="Replace a Nix store symlink with a file copy"
    )
    write_parser.add_argument("path")
    write_parser.set_defaults(func=write)

    restore_parser = subparsers.add_parser("restore", help="Restore the original Nix store symlink")
    restore_parser.add_argument("path")
    restore_parser.set_defaults(func=restore)

    return parser.parse_args()


def abs_path(path):
    return str(Path(os.path.normpath(Path(path).absolute())))


def write(path):
    p = Path(path)
    if not p.is_symlink():
        sys.exit(f"Error: {path} is not a symlink")

    target = p.readlink()
    if not str(target).startswith("/nix/store/"):
        sys.exit(f"Error: {path} does not point to the Nix store")
    if not target.is_file() and not target.is_dir():
        sys.exit(f"Error: {path} does not point to a file or directory")

    key = abs_path(p)
    state = load_state()
    state[key] = str(target)
    save_state(state)

    p.unlink()
    if target.is_dir():
        shutil.copytree(target, p)
        for f in p.rglob("*"):
            if f.is_file():
                f.chmod(f.stat().st_mode | 0o644)
    else:
        shutil.copy2(target, p)
        p.chmod(p.stat().st_mode | 0o644)


def restore(path):
    p = Path(path)
    key = abs_path(p)
    state = load_state()

    if key not in state:
        sys.exit(f"Error: no stored symlink for {path}")

    target = state.pop(key)
    if p.is_dir():
        shutil.rmtree(p)
    else:
        p.unlink()
    p.symlink_to(target)
    save_state(state)


def load_state():
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {}


def save_state(state):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2))


if __name__ == "__main__":
    main()
