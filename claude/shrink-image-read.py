#!/usr/bin/env python3
"""PreToolUse:Read — hand Claude a downscaled copy of a large image.

Images were 32% of every byte this account has ever read back from a tool, at
177 KB a read against 5.2 KB for a TypeScript file (dotfiles #2, diagrammo #877).
They are screenshots taken to check UI work, and a 596 KB one carries no more
information about a layout than a 90 KB one — but it stays in the context for
the rest of the session.

PreToolUse may return `updatedInput` to rewrite the call, so this resizes to a
cache file and points the Read at that instead. Entirely mechanical: no model,
no tokens, no round trip.

Contract: read the hook JSON on stdin, print either nothing or
  {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                          "permissionDecision": "allow",
                          "updatedInput": {...}}}
and ALWAYS exit 0. A hook that fails here must cost a full-size read, never the
read itself.
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys

MAX_BYTES = 200_000          # below this, the original is already cheap
MAX_DIM = 1400               # px on the long edge; keeps UI text legible
EXTS = ('.png', '.jpg', '.jpeg', '.webp')
CACHE = os.path.expanduser('~/.cache/claude-shrunk')


def resize(src, dst):
    """First available of ImageMagick 7, ImageMagick 6, macOS sips. False if none."""
    if shutil.which('magick'):
        cmd = ['magick', src, '-resize', f'{MAX_DIM}x{MAX_DIM}>', '-strip', dst]
    elif shutil.which('convert'):
        cmd = ['convert', src, '-resize', f'{MAX_DIM}x{MAX_DIM}>', '-strip', dst]
    elif shutil.which('sips'):
        cmd = ['sips', '--resampleHeightWidthMax', str(MAX_DIM), src, '--out', dst]
    else:
        return False
    return subprocess.run(cmd, capture_output=True, timeout=20).returncode == 0


def main():
    payload = json.load(sys.stdin)
    if payload.get('tool_name') != 'Read':
        return
    tool_input = payload.get('tool_input') or {}
    src = tool_input.get('file_path') or ''
    if not src.lower().endswith(EXTS):
        return

    st = os.stat(src)                       # missing file: let Read report it
    if st.st_size <= MAX_BYTES:
        return

    # Keyed on path + mtime + size, so an edited screenshot is re-shrunk and an
    # unchanged one is free on every later read.
    key = hashlib.sha256(
        f'{os.path.realpath(src)}|{st.st_mtime_ns}|{st.st_size}|{MAX_DIM}'.encode()
    ).hexdigest()[:16]
    os.makedirs(CACHE, exist_ok=True)
    dst = os.path.join(CACHE, key + os.path.splitext(src)[1].lower())

    if not os.path.exists(dst):
        if not resize(src, dst):
            return
    # A resize that grew the file, or produced nothing, is not worth taking.
    if not os.path.exists(dst) or os.path.getsize(dst) >= st.st_size:
        return

    print(json.dumps({'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'allow',
        'updatedInput': {**tool_input, 'file_path': dst},
    }}))


if __name__ == '__main__':
    try:
        main()
    except Exception:
        pass                                 # never cost the read itself
    sys.exit(0)
