---
name: omarchy-privilege-escalation
description: On Demian's Omarchy box, sudo needs a password and pkexec has no polkit agent; hand root work back as a script he runs in a real terminal window, NOT with `!`.
metadata:
  type: reference
---

On this machine **passwordless sudo is not configured** (`sudo -n true` fails), and
an agent session has no terminal for the password prompt.

**`pkexec` does not work either as of 2026-09-05.** No graphical polkit agent is
running — only `polkitd` itself — so pkexec falls back to a textual agent and
dies with:

- `--disable-internal-agent` → "No authentication agent found."
- plain `pkexec` → "Error opening current controlling terminal for the process
  (`/dev/tty`): No such device or address"

The agent session's `XDG_SESSION_TYPE` is `tty`, not the Hyprland session.

**`sudo` via Claude Code's `!` prefix does NOT work** (verified 2026-09-16).
sudo cannot read the password through it and is stopped by SIGTTIN instead: the
process sits in state `T` on the pts forever, printing nothing. It fails
*silently* — Demian sees no prompt and reports "nothing's happening", and the
stale stopped `sudo` processes pile up (three sat for an hour before being
noticed). Check with `ps -eo pid,stat,args | grep sudo` and look for `T`.
Nothing runs as root, so no partial state — just `kill -9` them and re-run.

**What to do instead:** stage the privileged work as a single commented shell
script (e.g. under `~/.cache/` or the session scratchpad), `bash -n` it, dry-run
any `sed` against the real file, then ask Demian to open a real terminal window
(`Super+Return`) and run it there, where he can type his password.
**Have the script `tee` its output to a fixed logfile** (e.g.
`exec > >(tee /tmp/<task>.log) 2>&1`) so the results can be read back afterward
without Demian copying anything into the conversation.

Narrow exceptions that *are* passwordless, per `sudo -n -l` on 2026-09-09:
only `asdcontrol`, `omarchy-dns {Cloudflare,Google,DHCP}`, and
`timedatectl set-timezone *`.

`~/omarchy-auto-update.sudoers` sits in the home directory and grants `pacman`,
`pacman-key`, `paccache`, `snapper`, `limine-snapper-restore` and
`systemctl reboot --no-wall`, but it has **never been installed** into
`/etc/sudoers.d/` -- `sudo -n pacman --version` still asks for a password. Do
not assume pacman is passwordless; check `sudo -n -l` first.

Also note **`/boot` is not readable by the `demian` user**, so inspecting
`limine.conf` or the UKI needs root the same way.
See [[mac-mini-hdmi-pixel-clock-cap]], [[anchor-mac-mini-hdd-bottleneck]] and
[[apple-display-isight-bandwidth]].
