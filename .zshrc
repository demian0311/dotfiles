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

# shell autocompletes for uv
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
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

# Always run Claude Code with permission prompts disabled
alias claude='claude --dangerously-skip-permissions'
#alias ddev='cd ~/code/diagrammo && pnpm run dev:app'

# Added by Diagrammo Terminal Opener
export PATH="$HOME/.local/bin:$PATH"


# ============================================================
# Diagrammo — run commands (cd in, start, auto-open URL)
# ============================================================
export DIAGRAMMO_ROOT="$HOME/code/diagrammo"

# Wait until $1 (port) accepts connections, then open $2 (url). Backgrounded + disowned.
_diagrammo_open() {
  ( for _ in {1..120}; do
      nc -z localhost "$1" >/dev/null 2>&1 && { open "$2"; break; }
      sleep 0.5
    done ) &!
}

# ---- Desktop app (native window, no URL) -------------------
diagrammo-run-app()  { cd "$DIAGRAMMO_ROOT" && pnpm app; }   # Tauri desktop app (kills stale dev first)
# dgmo watcher + desktop app (Vite :1420 + native window) — everyday loop.
# Root `pnpm dev` is now WATCHER-ONLY; the app's Vite/window come from `pnpm tauri dev`.
# Order matters: app's beforeDevCommand builds dgmo/dist once, THEN we start the
# tsup watcher — never both building dist at once (the torn-file race kill-dev.sh guards).
diagrammo-run-dev() {
  cd "$DIAGRAMMO_ROOT" || return
  bash kill-dev.sh
  trap 'bash "$DIAGRAMMO_ROOT/kill-dev.sh"' INT TERM
  ( cd diagrammo-app && pnpm tauri dev ) &   # builds dgmo, starts Vite :1420, opens window
  local app=$!
  echo "→ waiting for Vite on :1420 before starting dgmo watcher…"
  until lsof -nP -iTCP:1420 -sTCP:LISTEN -t >/dev/null 2>&1; do
    kill -0 "$app" 2>/dev/null || { echo "app exited before Vite came up"; bash "$DIAGRAMMO_ROOT/kill-dev.sh"; return 1; }
    sleep 0.5
  done
  echo "→ Vite up — starting dgmo watcher (edit dgmo/src → app HMRs)"
  ( cd dgmo && pnpm dev ) &
  wait "$app"
  bash "$DIAGRAMMO_ROOT/kill-dev.sh"
}

# ---- Web editor (online.diagrammo.app) ---------------------
diagrammo-run-online() {
  cd "$DIAGRAMMO_ROOT/diagrammo-app" || return
  _diagrammo_open 5173 "http://localhost:5173"
  pnpm dev:web --port 5173
}

# ---- AI guidance studio (dgmo-mcp authoring-guidance harness) ----
# Builds dgmo-mcp, dumps registry + gallery, then serves the guidance studio.
diagrammo-run-studio() {
  cd "$DIAGRAMMO_ROOT/dgmo-mcp" || return
  _diagrammo_open 5180 "http://localhost:5180"
  pnpm studio --port 5180
}

# ---- Diagrammo Console (server + web) ----------------------
# tsx API watcher on :5180 + Vite web on :5179 (concurrently, -k kills both on exit).
diagrammo-run-console() {
  cd "$DIAGRAMMO_ROOT/console" || return
  _diagrammo_open 5179 "http://localhost:5179"
  pnpm dev
}

# ---- Developer reference docs (standalone Astro site) ------
diagrammo-run-dev-docs() {
  cd "$DIAGRAMMO_ROOT/docs/developer-reference" || return
  _diagrammo_open 4322 "http://localhost:4322"
  pnpm dev --port 4322
}

# ---- Ecosystem docs (Starlight; how app + Workers + vendors fit) ----
diagrammo-run-ecosystem-docs() {
  cd "$DIAGRAMMO_ROOT/diagrammo-ecosystem-docs" || return
  _diagrammo_open 4323 "http://localhost:4323"
  pnpm dev --port 4323
}

# ---- Marketing site + guide/docs (Astro) -------------------
diagrammo-run-site() {
  cd "$DIAGRAMMO_ROOT/diagrammo_app_site" || return
  _diagrammo_open 4321 "http://localhost:4321"
  pnpm dev --port 4321
}

# ---- Wrapper integration fixtures (live preview) -----------
diagrammo-run-astro() {
  cd "$DIAGRAMMO_ROOT/astro-dgmo" && pnpm build || return
  cd tests/fixture; [ -d node_modules ] || pnpm install --no-frozen-lockfile
  _diagrammo_open 4331 "http://localhost:4331"
  pnpm dev --port 4331
}
diagrammo-run-docusaurus() {
  cd "$DIAGRAMMO_ROOT/docusaurus-plugin-dgmo" && pnpm build || return
  cd tests/fixture; [ -d node_modules ] || pnpm install --no-frozen-lockfile
  _diagrammo_open 3001 "http://localhost:3001"
  pnpm start --port 3001
}
diagrammo-run-fumadocs() {
  cd "$DIAGRAMMO_ROOT/fumadocs-dgmo" && pnpm build || return
  cd tests/fixture; [ -d node_modules ] || pnpm install --no-frozen-lockfile
  _diagrammo_open 3010 "http://localhost:3010"
  pnpm dev --port 3010
}

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
