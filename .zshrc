bindkey -v

# Enable truecolor (24-bit) in supported terminals
if [[ "$COLORTERM" == "truecolor" ]] || [[ "$TERM" == "xterm-256color" ]]; then
    export COLORTERM=truecolor
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/opt/homebrew/bin/"
export PATH="$PATH:/opt/homebrew/bin//"
#export PATH="$PATH:~/bin/"
export PATH="$HOME/bin/:$PATH"
export PATH="$HOME/.local/bin:$PATH"

autoload -Uz compinit
compinit -i  # -i = ignore insecure directories
autoload -Uz compdef


PS1='%{%F{#BF616A}%}%~%{%f%} %{%F{#A3BE8C}%}❱%{%f%} %{%F{#81A1C1}%}'
HOST=$(hostname -s)
case $HOST in
   MAC-HM32XJ06N0)
      eval "$(ssh-agent -s)"
      ssh-add -q ~/.ssh/id_ed25519_demian0311
      ;;
   *)
      #precmd() { print -Pn "%{\e[0m%}" }
    ;;
esac


# SDKMAN to manage Java
#source "$HOME/.sdkman/bin/sdkman-init.sh"
#source "$HOME/code/dotfiles/.zsh.aliases.sh"

source ~/.zsh.aliases.sh

~/bin/banner.sh

# Added by LM Studio CLI (lms)
#export PATH="$PATH:/Users/demian.neidetcher/.cache/lm-studio/bin"
# End of LM Studio CLI section

#export PATH="$PATH:/Users/demian/.lmstudio/bin"
# End of LM Studio CLI section
#
#export _ZO_DOCTOR=0
#eval "$(zoxide init zsh)"

# No `claude` alias here on purpose. Prompts are disabled by
# permissions.defaultMode in claude/settings.json, which applies to every
# launch path. An alias only ever covered shells the user typed in — cmux
# execs its own cmux-claude-wrapper via a PATH shim and never expanded it,
# so the alias that lived here looked load-bearing and was not.
#alias ddev='cd ~/code/diagrammo && pnpm run dev:app'

# Added by Diagrammo Terminal Opener
export PATH="$HOME/.local/bin:$PATH"


# ============================================================
# Diagrammo — `dg <name>` starts any server (scripts/dg in the workspace repo,
# linked to ~/.local/bin by `dg install`). `dg` alone lists them. It replaced
# the diagrammo-run-* functions on 2026-10-03: they lived here, apart from the
# package scripts they wrapped, and four had drifted onto ports the servers no
# longer served (diagrammo/diagrammo#1070).
# ============================================================
export DIAGRAMMO_ROOT="$HOME/code/diagrammo"
_dg() { compadd -- ${(f)"$(dg --names 2>/dev/null)"}; }
(( $+functions[compdef] )) && compdef _dg dg

# ---- cmux sidebar row colour: this workspace has no Claude in it -----------
# The row colour is session state. Claude's own hooks own three of the four
# states (green working, red waiting on you, yellow a session with nothing in
# it); this is the fourth — a workspace where no Claude session is open at all.
# Without it a terminal that never ran Claude, or one whose session was killed
# rather than exited, keeps whatever colour the last session left behind.
#
# Markers under $TMPDIR/claude-cmux-live/<workspace>/ are written by
# ~/.claude/cmux-session-start.py, one per pane, holding the claude pid. A flag
# file makes this a transition rather than a repaint on every prompt: one cmux
# call when the last session goes away, none while nothing changes.
_cmux_row_idle() {
  [[ -n "$CMUX_WORKSPACE_ID" ]] || return
  command -v cmux >/dev/null 2>&1 || return
  local tmp="${TMPDIR:-/tmp}"
  local dir="$tmp/claude-cmux-live/$CMUX_WORKSPACE_ID"
  local flag="$tmp/claude-cmux-idle-$CMUX_WORKSPACE_ID"
  local marker pid live=0
  for marker in "$dir"/*(N); do
    pid=$(<"$marker") 2>/dev/null
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      live=1
    else
      rm -f "$marker"
    fi
  done
  if (( live )); then
    rm -f "$flag"
    return
  fi
  [[ -f "$flag" ]] && return
  cmux workspace-action --action set-color --color '#3b6ea5' >/dev/null 2>&1 && : > "$flag"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _cmux_row_idle

# ---- cmux memory gauge: how big is each workspace, and is the machine ok -----
# Starts bin/cmux-mem's loop, which puts each workspace's size on its own sidebar
# row and warns before the laptop runs out of headroom.
#
# A shell is the ONLY thing that can start it. cmux's socket is `cmuxOnly`, so it
# refuses every process launched from outside cmux — a LaunchAgent for this runs
# forever and silently achieves nothing, which is exactly what cmux-tidy's has
# been doing. Access is inherited at spawn rather than checked live, so the loop
# keeps working after this terminal closes and it is orphaned to PID 1.
#
# The pidfile test keeps a new terminal from paying for a Python start just to be
# told the daemon is already up.
_cmux_mem_daemon() {
  [[ -n "$CMUX_WORKSPACE_ID" ]] || return
  local bin="$HOME/code/dotfiles/bin/cmux-mem"
  local pidfile="$HOME/Library/Caches/cmux-mem.pid"
  [[ -x "$bin" ]] || return
  if [[ -f "$pidfile" ]] && kill -0 "$(<"$pidfile")" 2>/dev/null; then
    return
  fi
  ( nohup "$bin" --daemon --log "$HOME/Library/Logs/cmux-mem.log" >/dev/null 2>&1 & )
}
_cmux_mem_daemon

# ---- cmux agent badges: which agent is in this workspace -------------------
# Starts bin/cmux-agents' loop, which puts the AGENT'S NAME on each workspace
# row. cmux's own pills say the lifecycle (`Running`, `Idle`) in one styling for
# every agent, so with several running side by side the sidebar could not answer
# "which one is this". The badge answers it; the lifecycle pills are left alone.
#
# Same launch constraint as the memory gauge above — cmux's socket is `cmuxOnly`,
# so a shell inside cmux is the only thing that can start it, and the loop keeps
# working once orphaned. The pidfile keeps every new terminal from paying for a
# Python start just to be told the daemon is already up.
_cmux_agents_daemon() {
  [[ -n "$CMUX_WORKSPACE_ID" ]] || return
  local bin="$HOME/code/dotfiles/bin/cmux-agents"
  local pidfile="$HOME/Library/Caches/cmux-agents.pid"
  [[ -x "$bin" ]] || return
  if [[ -f "$pidfile" ]] && kill -0 "$(<"$pidfile")" 2>/dev/null; then
    return
  fi
  ( nohup "$bin" --daemon >/dev/null 2>&1 & )
}
_cmux_agents_daemon
