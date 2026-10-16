---
name: dgmo-pane-mod
description: Claude Code mod that renders .dgmo edits in a live pane; where it lives and the ssh image trap
metadata:
  type: project
---
Built 2026-10-07: `dgmo-pane` mod, repo `~/code/diagrammo/dgmo-pane`, public at github.com/diagrammo/dgmo-pane (user created it by hand 2026-10-07 after the auto-mode classifier blocked `gh repo create --public`). Local install removed so the user could test the real `/plugin install` path. On every Write/Edit of a `.dgmo` file it runs `dgmo --json` to PNG+SVG, draws the pane (`/dgmo-pane [file]`), and adds parser errors to the tool result's `context` so Claude sees them. Confirmed by the user, working over ssh, 2026-10-07.

- ssh trap: an `Image` `{ file }` source is read by the terminal on the CLIENT machine (user runs Ghostty on a Mac, ssh'd into this Linux box), so it drew a blank box. Inline `{ png: base64 }` (≤2 MiB) works over ssh.

Ideas not built yet: `show_diagram` tool (draw without a file), theme following the terminal, pushing to GitHub.

Decided 2026-10-07: NOT on the marketing site (small audience: Claude Code + Ghostty/kitty + early-access mod API that may break). Mentioned only as an optional line in `dgmo install claude-code` output (dgmo e13ec8f8, ships with the next dgmo release). Revisit when the mod API leaves early access.
