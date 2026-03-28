#!/usr/bin/env python3
import json
import sys
import os
import time

data = json.load(sys.stdin)

# Context window
cw = data.get('context_window', {})
pct = cw.get('used_percentage') or 0
transcript_path = data.get('transcript_path', '')
cwd = data.get('cwd', '') or data.get('workspace', {}).get('current_dir', '')
session_id = data.get('session_id', '')

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

# Session note
session_note = ''
NOTES_DIR = os.path.expanduser('~/.claude/session-notes')
cwd_slug = cwd.strip('/').replace('/', '-')
for candidate in ([session_id, cwd_slug] if session_id else [cwd_slug]):
    if not candidate:
        continue
    note_path = os.path.join(NOTES_DIR, candidate + '.txt')
    if os.path.exists(note_path):
        try:
            with open(note_path) as f:
                session_note = f.read().strip()
            if session_note:
                break
        except Exception:
            pass

# Truncate session note at 40 chars
NOTE_MAX = 40
if len(session_note) > NOTE_MAX:
    session_note = session_note[:NOTE_MAX - 1] + '...'

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
                        text = content.strip().replace('\n', ' ')
                        slug = text[:42] + ('...' if len(text) > 42 else '')
                        break
            except Exception:
                continue
    except Exception:
        pass

MAGENTA = '\033[35m'

# Assemble: project  C:X%  S:X%  W:X%    ▸ last message  session_note
project_part = f"{CYAN}{BOLD}{project_label}{RESET}" if project_label else ''
note_part = f"{MAGENTA}{BOLD}{session_note}{RESET}" if session_note else ''

left_parts = []
left_parts.append(ctx_part)
if five_part:
    left_parts.append(five_part)
if week_part:
    left_parts.append(week_part)
if project_part:
    left_parts.append(project_part)

right_parts = []
if slug:
    right_parts.append(f"{DIM}▸ {slug}{RESET}")
if note_part:
    right_parts.append(note_part)

left = '  '.join(left_parts)
right = '  '.join(right_parts)

if right:
    print(f" {left}    {right}")
else:
    print(f" {left}")
