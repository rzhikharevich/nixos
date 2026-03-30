#!/usr/bin/env python3

import argparse
import asyncio
from dataclasses import dataclass
import json
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import asyncinotify
except ImportError:
    asyncinotify = None

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "cownix"
STATE_FILE = STATE_DIR / "cownix.json"


async def main():
    args = parse_args()
    await args.func(args)


def parse_args():
    parser = argparse.ArgumentParser(description="Copy and restore Nix store symlinks")
    subparsers = parser.add_subparsers(required=True)

    write_parser = subparsers.add_parser(
        "write", help="Replace a Nix store symlink with a file copy"
    )
    write_parser.add_argument("path")
    write_parser.add_argument(
        "-o", "--open", action="store_true",
        help="Open the file in $EDITOR",
    )
    if asyncinotify:
        write_parser.add_argument(
            "-x", "--execute", metavar="CMD",
            help="Run CMD on each file modification (requires --open)",
        )
    write_parser.set_defaults(execute=None)
    write_parser.add_argument(
        "-r", "--restore-on-close", action="store_true",
        help="Restore the file after $EDITOR is closed",
    )
    write_parser.set_defaults(func=write)

    restore_parser = subparsers.add_parser("restore", help="Restore the original Nix store symlink")
    restore_parser.add_argument("path")
    restore_parser.set_defaults(func=restore)

    return parser.parse_args()


def abs_path(path):
    return str(Path(os.path.normpath(Path(path).absolute())))


async def write(args):
    path = args.path
    p = Path(path)
    if not p.is_symlink():
        sys.exit(f"Error: {path} is not a symlink")
    if args.execute and not args.open:
        sys.exit("Error: --execute requires --open")

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

    if args.open:
        editor = os.environ.get("EDITOR", "nano")
        if args.execute:
            watcher = asyncio.create_task(watch_and_exec(p, args.execute))
            proc = None
            try:
                proc = await asyncio.create_subprocess_shell(f"{editor} {shlex.quote(path)}")
                await proc.wait()
            except (asyncio.CancelledError, KeyboardInterrupt):
                pass
            finally:
                if proc is not None and proc.returncode is None:
                    proc.terminate()

                watcher.cancel()
                try:
                    await watcher
                except (asyncio.CancelledError, KeyboardInterrupt):
                    pass
        else:
            subprocess.call([editor, p])

        subprocess.call(["diff", "--color", "--unified", target, p])

        if args.restore_on_close:
            await restore(RestoreArgs(path=path))


async def watch_and_exec(path, cmd):
    with asyncinotify.Inotify() as inotify:
        inotify.add_watch(
            path.parent,
            asyncinotify.Mask.MOVED_TO | asyncinotify.Mask.MODIFY,
        )
        async for event in inotify:
            if str(event.name) == path.name:
                subprocess.call(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


@dataclass(frozen=True)
class RestoreArgs:
    path: str


async def restore(args):
    path = args.path
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
    asyncio.run(main())
