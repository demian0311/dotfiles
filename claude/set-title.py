#!/usr/bin/env python3
import json
import sys
import os

data = json.load(sys.stdin)
transcript_path = data.get('transcript_path', '')

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
                        slug = text[:50] + ('…' if len(text) > 50 else '')
                        break
            except Exception:
                continue
    except Exception:
        pass

title = f"Claude — {slug}" if slug else "Claude"
# OSC 0 sets both icon and window title
sys.stdout.write(f"\033]0;{title}\007")
sys.stdout.flush()
