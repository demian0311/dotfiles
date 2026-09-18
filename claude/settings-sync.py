#!/usr/bin/env python3
"""Generate ~/.claude/settings.json from the tracked base plus a per-host overlay.

Why this is not a symlink like everything else in install.sh: the file is not the
same on every machine. Twelve of the Mac's hooks are macOS-only — afplay, five
cmux scripts, caffeinate — and cmux does not exist on anchor, so a symlinked
settings.json would fire twelve failing hooks per session there. Splitting it is
what lets one repo dress both machines.

    settings.base.json     portable: permissions, plugins, autoMode, theme, …
    settings.<host>.json   hooks and statusLine, which are machine-specific
                           host is `macos` or `linux`, from uname

The overlay's paths are written as {{HOME}} and {{REPO_ROOT}} placeholders, since
the same hook is /Users/demian on one box and /home/demian on the other.

🔴 Claude Code REWRITES ~/.claude/settings.json whenever a setting changes from
inside a session — /model, the theme picker, installing a plugin. So this reads
the live file first and adopts any top-level key that has drifted back into
settings.base.json, then regenerates. That is what makes `enabledPlugins` travel:
install a plugin on the Mac, and the next run here writes it into the repo, where
a `git pull` carries it to anchor and the plugin step installs it. Overlay-owned
keys are never adopted — they are supposed to differ per machine.

A key that has been DELETED from the live file is not adopted as a deletion. A
partial write would otherwise silently strip the repo copy, and nothing would say
so. Remove it from settings.base.json by hand instead.

Usage: settings-sync.py <repo_root> [--quiet]
"""

import collections
import json
import os
import platform
import shutil
import sys
import time

OVERLAY_OWNED = ("hooks", "statusLine")


def load(path):
    try:
        with open(path) as f:
            return json.load(f, object_pairs_hook=collections.OrderedDict)
    except (OSError, ValueError):
        return None


def dump(path, obj):
    tmp = path + ".tmp-%d" % os.getpid()
    with open(tmp, "w") as f:
        json.dump(obj, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)


def substitute(obj, mapping):
    if isinstance(obj, str):
        for k, v in mapping.items():
            obj = obj.replace(k, v)
        return obj
    if isinstance(obj, list):
        return [substitute(x, mapping) for x in obj]
    if isinstance(obj, dict):
        return collections.OrderedDict((k, substitute(v, mapping)) for k, v in obj.items())
    return obj


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    quiet = "--quiet" in sys.argv[1:]
    repo_root = os.path.abspath(args[0]) if args else os.path.dirname(
        os.path.dirname(os.path.abspath(__file__)))
    home = os.path.expanduser("~")

    claude_dir = os.path.join(repo_root, "claude")
    host = "macos" if platform.system() == "Darwin" else "linux"

    base_path = os.path.join(claude_dir, "settings.base.json")
    overlay_path = os.path.join(claude_dir, "settings.%s.json" % host)
    live_path = os.path.join(home, ".claude", "settings.json")

    base = load(base_path)
    if base is None:
        print("skip   settings.json (no settings.base.json in repo)")
        return 0

    overlay = load(overlay_path) or collections.OrderedDict()
    if not os.path.exists(overlay_path):
        print("warn   settings.json (no overlay for host '%s'; base only)" % host)

    overlay = substitute(overlay, {"{{HOME}}": home, "{{REPO_ROOT}}": repo_root})

    def generate():
        merged = collections.OrderedDict(base)
        merged.update(overlay)
        return merged

    generated = generate()

    # A symlink here is the pre-split layout. Read what it points at before
    # removing it, so a setting that only ever existed on the live file survives.
    live = None
    if os.path.islink(live_path):
        live = load(live_path)
        os.unlink(live_path)
        print("unlink settings.json (was a symlink; now generated per host)")
    elif os.path.exists(live_path):
        live = load(live_path)

    adopted = []
    if live is not None:
        for key, value in live.items():
            if key in OVERLAY_OWNED:
                continue
            if key not in generated or generated[key] != value:
                base[key] = value
                adopted.append(key)

    if adopted:
        backup = live_path + ".bak-%s" % time.strftime("%Y%m%d-%H%M%S")
        try:
            shutil.copy(live_path, backup)
        except OSError:
            backup = None
        dump(base_path, base)
        generated = generate()
        print("adopt  settings.json (%s -> settings.base.json%s)" % (
            ", ".join(adopted), "; original kept as %s" % os.path.basename(backup) if backup else ""))

    if live == generated and not adopted:
        if not quiet:
            print("ok     settings.json (generated, host %s)" % host)
        return 0

    os.makedirs(os.path.dirname(live_path), exist_ok=True)
    dump(live_path, generated)
    print("write  settings.json (base + settings.%s.json)" % host)
    return 0


if __name__ == "__main__":
    sys.exit(main())
