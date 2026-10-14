#!/bin/sh
# Tests for .githooks/pre-push (diagrammo/diagrammo#1147).
#
#   sh .githooks/tests/pre-push.test.sh
#
# Each case builds a throwaway clone of a throwaway bare remote, commits a
# fixture, and pushes with core.hooksPath pointed at THIS checkout's .githooks.
# The assertion is on the push itself: whether the remote moved, and what the
# hook printed. Exits non-zero when any case fails.

HOOKS=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-pre-push-test.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
pass=0
fail=0

ok()  { pass=$((pass + 1)); printf 'ok   %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL %s\n' "$1"; sed 's/^/     | /' "$WORK/out"; }

# A fresh remote holding one commit, and a clone of it in $WORK/clone.
setup() {
  rm -rf "$WORK/remote.git" "$WORK/clone"
  git init -q --bare -b master "$WORK/remote.git"
  git init -q -b master "$WORK/clone"
  cd "$WORK/clone" || exit 1
  git config user.email test@example.com
  git config user.name test
  mkdir -p bin claude
  printf '#!/bin/bash\necho hi\n' > bin/tool
  printf '# rules\n' > claude/CLAUDE.md
  git add bin/tool claude/CLAUDE.md
  git commit -q -m base
  git remote add origin "$WORK/remote.git"
  git push -q origin master
}

# commit <message> <path> <content>
commit() {
  mkdir -p "$(dirname "$2")"
  printf '%s\n' "$3" > "$2"
  git add "$2"
  git commit -q -F - <<EOF
$1
EOF
}

# push [ref] — the hook under test runs; output to $WORK/out.
push() {
  git -c core.hooksPath="$HOOKS" push origin "${1:-master}" > "$WORK/out" 2>&1
}

landed() { [ "$(git -C "$WORK/remote.git" rev-parse "${1:-master}" 2>/dev/null)" = "$(git rev-parse HEAD)" ]; }

TRAILER='Nightly-Run: bob-night 2026-10-13
Nightly-Issue: diagrammo/diagrammo#1147'

# --- cases ---

setup
commit 'a person edits the global rules' claude/CLAUDE.md '# new rules'
if push && landed && grep -q "^pre-push: gating $(git rev-parse --short HEAD)" "$WORK/out"; then
  ok "a person's push lands and prints the gating marker"
else bad "a person's push lands and prints the gating marker"; fi

setup
commit "run edits the global rules

$TRAILER" claude/CLAUDE.md '# rewritten by a run'
if ! push && ! landed && grep -q 'outside bin/ and .githooks/' "$WORK/out" \
   && grep -q 'claude/CLAUDE.md' "$WORK/out"; then
  ok "a run's commit touching claude/ is refused and names the file"
else bad "a run's commit touching claude/ is refused and names the file"; fi

setup
commit "run fixes a script

$TRAILER" bin/tool '#!/bin/bash
echo fixed'
if push && landed; then ok "a run's commit touching only bin/ lands"
else bad "a run's commit touching only bin/ lands"; fi

setup
commit "run repairs the gate

$TRAILER" .githooks/README '# notes'
if push && landed; then ok "a run's commit touching only .githooks/ lands"
else bad "a run's commit touching only .githooks/ lands"; fi

setup
commit "run fixes a script

$TRAILER" bin/tool '#!/bin/bash
echo fixed'
commit 'a person edits settings' claude/settings.json '{}'
commit "run touches settings later

$TRAILER" claude/settings.json '{"x":1}'
if ! push && ! landed; then ok "one run commit outside bin/ in a range of three refuses the push"
else bad "one run commit outside bin/ in a range of three refuses the push"; fi

setup
commit 'a person breaks a script' bin/tool '#!/bin/bash
if then fi'
if ! push && ! landed && grep -q 'bin/tool does not parse' "$WORK/out"; then
  ok "a bin/ script that does not parse is refused"
else bad "a bin/ script that does not parse is refused"; fi

setup
commit 'a person breaks install.sh' claude/install.sh '#!/usr/bin/env sh
case x in'
if ! push && ! landed && grep -q 'claude/install.sh does not parse' "$WORK/out"; then
  ok "claude/install.sh that does not parse is refused"
else bad "claude/install.sh that does not parse is refused"; fi

setup
git checkout -q -b topic
commit "run on a new branch

$TRAILER" claude/CLAUDE.md '# rewritten on a branch'
if ! push topic && ! landed topic; then ok "a new branch's run commit outside bin/ is refused"
else bad "a new branch's run commit outside bin/ is refused"; fi

setup
if push && grep -q '^pre-push: nothing to gate' "$WORK/out"; then
  ok "a push with no new commits gates nothing and succeeds"
else bad "a push with no new commits gates nothing and succeeds"; fi

if command -v gitleaks >/dev/null 2>&1; then
  setup
  # Built at run time so no token-shaped string is ever committed here.
  tail=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 36)
  commit 'a person pastes a token' bin/env "GH_TOKEN=ghp_$tail"
  if ! push && ! landed && grep -q 'gitleaks found something' "$WORK/out"; then
    ok "a token-shaped secret in a pushed commit is refused"
  else bad "a token-shaped secret in a pushed commit is refused"; fi
else
  printf 'skip a token-shaped secret in a pushed commit is refused (gitleaks not on PATH)\n'
fi

printf '\n%s/%s passed\n' "$pass" "$((pass + fail))"
[ "$fail" = 0 ]
