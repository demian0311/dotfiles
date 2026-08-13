#!/usr/bin/env python3
import json
import sys
import os
import re
import shutil
import subprocess
import time

data = json.load(sys.stdin)

# Context window
cw = data.get('context_window', {})
pct = cw.get('used_percentage') or 0
transcript_path = data.get('transcript_path', '')
cwd = data.get('cwd', '') or data.get('workspace', {}).get('current_dir', '')

# Project label — map known repo paths to short display names
HOME = os.path.expanduser('~')
PROJECT_MAP = [
    (HOME + '/code/diagrammo/diagrammo-app',   'diagrammo-app'),
    (HOME + '/code/diagrammo/dgmo',             'dgmo'),
    (HOME + '/code/diagrammo/obsidian-dgmo',    'obsidian-dgmo'),
    (HOME + '/code/diagrammo/diagrammo_app_site', 'website'),
    (HOME + '/code/diagrammo/homebrew-dgmo',    'homebrew-dgmo'),
    (HOME + '/code/diagrammo',                  'diagrammo'),
]

project_label = ''
for path, label in PROJECT_MAP:
    if cwd == path or cwd.startswith(path + '/'):
        project_label = label
        break

if not project_label and cwd:
    parts = cwd.rstrip('/').split('/')
    project_label = '/'.join(parts[-2:]) if len(parts) >= 2 else parts[-1]

# Rate limits
rate_limits = data.get('rate_limits', {})
five_hour = rate_limits.get('five_hour', {})
seven_day = rate_limits.get('seven_day', {})
five_pct       = five_hour.get('used_percentage')
five_resets_at = five_hour.get('resets_at')
week_pct       = seven_day.get('used_percentage')
week_resets_at = seven_day.get('resets_at')

# Colors
RESET  = '\033[0m'
BOLD   = '\033[1m'
DIM    = '\033[2m'
RED    = '\033[31m'
YELLOW = '\033[33m'
ORANGE = '\033[38;5;214m'
GREEN  = '\033[32m'
CYAN   = '\033[36m'
ITALIC = '\033[3m'
BR_MAGENTA = '\033[95m'
BR_BLUE    = '\033[94m'
BR_GREEN   = '\033[92m'
BR_YELLOW  = '\033[93m'

# Which model is answering. Shown first and colored per family, because the
# expensive one and the cheap one otherwise look identical from the prompt.
model = data.get('model', {}) or {}
model_name = (model.get('display_name') or '').strip()
model_id = (model.get('id') or '').lower()

MODEL_COLORS = [
    ('fable',  BR_MAGENTA),
    ('mythos', BR_MAGENTA),
    ('opus',   BR_BLUE),
    ('sonnet', BR_GREEN),
    ('haiku',  BR_YELLOW),
]
model_color = CYAN
for needle, color in MODEL_COLORS:
    if needle in model_id or needle in model_name.lower():
        model_color = color
        break

# "Claude Opus 5 (1M context)" -> "Opus 5 1M"
if model_name.startswith('Claude '):
    model_name = model_name[len('Claude '):]
model_name = model_name.replace('(1M context)', '1M').replace('  ', ' ').strip()
if not model_name:
    model_name = model_id or '?'

# Three lengths, tried widest-first when the row has to fit a narrow pane. The
# family word survives every trim: "Opus" answers the question this is here for,
# where an initial would not.
words = model_name.split()
MODEL_VARIANTS = [model_name, ' '.join(words[:2]), words[0]]

def fmt_model(name):
    part = f"{model_color}{BOLD}{name}{RESET}"
    if data.get('fast_mode'):
        part += f"{DIM}·fast{RESET}"
    return part

# Reasoning effort, dim beside the model — it changes how the same model answers.
effort_level = (data.get('effort') or {}).get('level') or ''
effort_part = f"{DIM}{effort_level}{RESET}" if effort_level else ''

def pct_color(p):
    """Green 0-49%, yellow 50-69%, orange 70-84%, red 85%+"""
    if p is None:
        return DIM
    if p >= 85:
        return RED
    if p >= 70:
        return ORANGE
    if p >= 50:
        return YELLOW
    return GREEN

# Context indicator: C:XX%
ctx_color = pct_color(pct)
ctx_part = f"{DIM}C:{RESET}{ctx_color}{BOLD}{pct:.0f}%{RESET}"

# Rate limit indicators: S:XX% 1h23m  W:XX% 4d3h
def fmt_reset(resets_at):
    """Return compact time-until-reset string, e.g. '1h23m', '4d3h', '45m'."""
    if not resets_at:
        return ''
    secs = int(resets_at) - int(time.time())
    if secs <= 0:
        return ''
    days  = secs // 86400
    hours = (secs % 86400) // 3600
    mins  = (secs % 3600) // 60
    if days >= 1:
        return f"{days}d{hours}h"
    if hours >= 1:
        return f"{hours}h{mins:02d}m"
    return f"{mins}m"

def fmt_limit(label, p, resets_at=None):
    if p is None:
        return ''
    c = pct_color(p)
    reset_str = fmt_reset(resets_at)
    reset_part = f" {DIM}{reset_str}{RESET}" if reset_str else ''
    return f"{DIM}{label}:{RESET}{c}{BOLD}{p:.0f}%{RESET}{reset_part}"

five_part = fmt_limit('S', five_pct, five_resets_at)
week_part = fmt_limit('W', week_pct, week_resets_at)

# The hand-written note in ~/.claude/session-notes was dropped 2026-08-13: no
# writer ever existed, and the per-directory fallback meant one file from May
# reappeared in every later session in that directory. The transcript slug below
# is the same idea, derived from something that cannot go stale.

# Working-on slug: last user message from transcript
slug = ''
if transcript_path and os.path.exists(transcript_path):
    try:
        with open(transcript_path) as f:
            lines = f.readlines()
        for line in reversed(lines):
            try:
                obj = json.loads(line)
                if obj.get('role') == 'user':
                    content = obj.get('content', '')
                    if isinstance(content, list):
                        for block in content:
                            if isinstance(block, dict) and block.get('type') == 'text':
                                content = block.get('text', '')
                                break
                    if isinstance(content, str) and content.strip():
                        slug = content.strip().replace('\n', ' ')
                        break
            except Exception:
                continue
    except Exception:
        pass

# Assemble: C:X%  S:X%  W:X%  model effort  project    ▸ last message
# The two budgets lead because they are what runs out; the model sits after them
# and before the project, close enough to read in the same glance.
project_part = f"{CYAN}{BOLD}{project_label}{RESET}" if project_label else ''

ANSI = re.compile(r'\033\[[0-9;]*m')

def render(model_variant, with_effort, slug_max):
    left_parts = [ctx_part]
    if five_part:
        left_parts.append(five_part)
    if week_part:
        left_parts.append(week_part)
    model_group = fmt_model(model_variant)
    if with_effort and effort_part:
        model_group += ' ' + effort_part
    left_parts.append(model_group)
    if project_part:
        left_parts.append(project_part)

    line = ' ' + '  '.join(left_parts)
    if slug and slug_max > 0:
        text = slug if len(slug) <= slug_max else slug[:slug_max - 1] + '…'
        line += f"    {DIM}▸ {text}{RESET}"
    return line

# Widest form that fits the pane wins, giving up the least-missed thing first:
# the trailing message, then the effort word, then the model down to its family
# name. The last rung prints even if it still overflows.
LADDER = [
    (0, True,  42),
    (0, True,  28),
    (0, True,  16),
    (0, True,   0),
    (0, False,  0),
    (1, False,  0),
    (2, False,  0),
]

width = shutil.get_terminal_size((120, 24)).columns
line = ''
for model_idx, with_effort, slug_max in LADDER:
    line = render(MODEL_VARIANTS[model_idx], with_effort, slug_max)
    if len(ANSI.sub('', line)) <= width:
        break

print(line)

# ---------------------------------------------------------------------------
# Hand the context percentage to cmux-throbber.py, which draws it as a block bar
# inside the sidebar pill — icon then bar, one line, instead of cmux's separate
# progress row underneath.
# The row's COLOUR is not context either: it is session state, written by the
# same hooks — red stopped/waiting on you, green working, blue no agent.
# Numbers are deliberately NOT written anywhere on the row: C/S/W already sit in
# the footer above, and repeating them is the same fact twice.
# Cleared again by cmux-session-end.py on SessionEnd. Best effort throughout —
# any failure leaves the status line above untouched.
# ---------------------------------------------------------------------------

def push_to_cmux():
    panel = os.environ.get('CMUX_PANEL_ID')
    if not panel:
        return
    # A plain file, keyed by pane like everything else the throbber owns. No
    # cmux call from here at all any more: the spin loop reads this each tick,
    # so a render costs one small write instead of spawning a process.
    path = os.path.join(os.environ.get('TMPDIR', '/tmp'), 'claude-cmux-ctx-%s' % panel)
    try:
        with open(path, 'w') as f:
            f.write('%.1f' % pct)
    except Exception:
        pass


try:
    push_to_cmux()
except Exception:
    pass
