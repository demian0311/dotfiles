---
name: auto-mode-denies-passphraseless-gpg
description: "Auto mode's classifier refuses `gpg --passphrase ''` as Security Weaken; hand passphrase-less key generation back to the user rather than restructuring the command."
metadata:
  type: feedback
---

Auto mode's permission classifier denies `gpg --batch --pinentry-mode loopback --passphrase ''
--quick-generate-key ...` with **Security Weaken**. It is the empty passphrase that trips it,
not the key generation. `gpg --armor --export-secret-keys | gh secret set ...` is the same
shape and should be expected to trip it too.

**Why:** a passphrase-less private key reads as weakening key protection, which is a fair
default. For a CI signing key it is often the deliberate choice — a `*_PASSPHRASE` secret
stored in the same vault as the key it protects buys nothing. Hit 2026-09-17 minting the
Diagrammo Arch repository signing key (diagrammo/diagrammo#771).

**How to apply:** do not restructure the command to slip past the check — that is what the
denial exists to prevent. Hand it back for the user to run with `! `, which is not blocked and
needs no TTY (the `--batch --pinentry-mode loopback` flags bypass pinentry, and this session
has no tty). Offer the alternatives once: a `Bash(gpg --batch --pinentry-mode loopback:*)`
permission rule, or reconsidering the passphrase. Distinct from
[[omarchy-privilege-escalation]], which is about sudo having no way to prompt here — these
commands need no root at all.
