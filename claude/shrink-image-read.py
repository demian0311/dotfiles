#!/usr/bin/env python3
"""PreToolUse:Read — hand Claude a downscaled copy of a large image.

Images were 32% of every byte this account has ever read back from a tool, at
177 KB a read against 5.2 KB for a TypeScript file (dotfiles #2, diagrammo #877).
They are screenshots taken to check UI work, and a screenshot carries no more
information about a layout at 2400 px than at 1400 px — but it stays in the
context for the rest of the session, re-billed on every later turn.

WHAT AN IMAGE COSTS, and why this gates on pixels rather than bytes.
Claude bills an image in 28x28 visual tokens: ceil(w/28) * ceil(h/28). Models
from Claude 4.7 on are the high-resolution tier — the API downscales only above
2576 px on the long edge, and caps at 4784 visual tokens. (Earlier models were
the standard tier: 1568 px, 1568 tokens.) So on a current model an oversized
screenshot costs up to 4784 tokens, not the ~1600 the older tier capped it at,
and Anthropic's own guidance is to downsample before sending when the extra
fidelity is not needed. Measured 2026-09-21 against
platform.claude.com/docs/en/build-with-claude/vision.

    a 2400x1600 render     4784 tokens   ->  1400x933   1700 tokens
    a 2400x4000 render     4784 tokens   ->  840x1400   1500 tokens

BYTES DO NOT PREDICT THAT. This hook gated on file size until 2026-09-21, and
141 of 400 PNGs in the diagrammo tree sat under the old 200 KB threshold while
still costing the full 4784 — flat-colour UI and diagram renders compress
beautifully and say nothing about their pixel count. Worse, re-encoding one at
1400 px can GROW it: a 2400x1600 venn render went 128,396 B -> 141,909 B while
going 4784 -> 1700 tokens, so the old "only keep it if the file got smaller"
acceptance test rejected precisely the case with the most to save.

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
import math
import os
import shutil
import struct
import subprocess
import sys

MAX_DIM = 1400               # px on the long edge; keeps UI text legible
FALLBACK_MAX_BYTES = 200_000 # only when the dimensions cannot be read
EXTS = ('.png', '.jpg', '.jpeg', '.webp', '.gif')
CACHE = os.path.expanduser('~/.cache/claude-shrunk')


def dimensions(path):
    """(width, height) from the file header, or None. Pure stdlib, so this
    behaves the same on the Mac and on anchor, where sips does not exist."""
    with open(path, 'rb') as fh:
        head = fh.read(32)
        if head[:8] == b'\x89PNG\r\n\x1a\n':
            return struct.unpack('>II', head[16:24])
        if head[:6] in (b'GIF87a', b'GIF89a'):
            return struct.unpack('<HH', head[6:10])
        if head[:4] == b'RIFF' and head[8:12] == b'WEBP':
            chunk = head[12:16]
            if chunk == b'VP8X':
                w = int.from_bytes(head[24:27], 'little') + 1
                h = int.from_bytes(head[27:30], 'little') + 1
                return w, h
            if chunk == b'VP8L':
                bits = int.from_bytes(head[21:25], 'little')
                return (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1
            if chunk == b'VP8 ':
                return struct.unpack('<HH', head[26:30])[0] & 0x3FFF, \
                       struct.unpack('<HH', head[26:30])[1] & 0x3FFF
        if head[:2] == b'\xff\xd8':          # JPEG: walk to the frame header
            fh.seek(2)
            while True:
                marker = fh.read(2)
                if len(marker) < 2 or marker[0] != 0xFF:
                    return None
                size = struct.unpack('>H', fh.read(2))[0]
                # SOF0..SOF15, minus the DHT/JPG/DAC markers interleaved in that range
                if marker[1] in set(range(0xC0, 0xD0)) - {0xC4, 0xC8, 0xCC}:
                    # frame header: precision, height, width
                    _, height, width = struct.unpack('>BHH', fh.read(5))
                    return width, height
                fh.seek(size - 2, os.SEEK_CUR)
    return None


def visual_tokens(w, h):
    """What the API bills this image at, on the high-resolution tier."""
    scale = min(1.0, 2576 / max(w, h))
    return min(math.ceil(w * scale / 28) * math.ceil(h * scale / 28), 4784)


def resize(src, dst):
    """First available of ImageMagick 7, ImageMagick 6, macOS sips. False if none.
    All three forms only ever shrink, so a small image is never blown up."""
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
    try:
        dims = dimensions(src)
    except Exception:
        dims = None
    if dims:
        if max(dims) <= MAX_DIM:            # already cheap; nothing to win
            return
    elif st.st_size <= FALLBACK_MAX_BYTES:
        return                              # unreadable header, old heuristic

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
    if not os.path.exists(dst) or os.path.getsize(dst) == 0:
        return

    # Accept on PIXELS, never on bytes: re-encoding a flat-colour render at
    # 1400 px routinely produces a LARGER file that costs a third of the tokens.
    try:
        out = dimensions(dst)
    except Exception:
        out = None
    if dims and out and visual_tokens(*out) >= visual_tokens(*dims):
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
