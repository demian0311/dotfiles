---
name: ui-preferences
description: How UI should be built here — reach a new action through an existing surface, never a dialog that asks a question, direct manipulation means zero affordance, and the hover-explains/click-acts split. Plus the separate failure mode of operator tools, which name things after the mechanism instead of the operator's question. Load before adding a control, dialog, panel, empty state or dashboard.
---

# UI preferences

- **Reach a new action through an existing surface** — context menu, native menus, settings
  drawer — before adding any persistent button, icon or rail entry. Discoverability rarely
  justifies permanent chrome.
- **Never design a dialog that asks a question.** Act on the context-derived default and put
  the alternative in the confirmation toast; persistent settings are ambient state behind an
  anchored menu, and an inapplicable option is omitted rather than disabled. A dialog whose
  every row is an action is fine.
- **Direct manipulation means zero affordance.** When the ask is "edit it and see it
  update", the thing shown IS the editable thing and saving is silent — no pencil button, no
  edit mode, no explicit commit, no confirmation notice. Add a mode or a confirm step only
  when data loss is at stake.
- **A hover surface explains; a click surface acts.** A surface doing both is the tell that
  something is bolted on, and the fix is to move the action to a surface that is already
  clicked rather than to grow a footer on the explainer. The corollary is a rule about
  closing: a surface holding an action must survive the pointer crossing the gap to reach
  it, while one holding none closes immediately. Learned 2026-08-17 from a status card that
  had grown a *Check now* button and read as two components stapled together.

**Operator tools** — dashboards, harnesses, anything built to be *used* rather than demoed —
have their own failure mode, which is naming things after the mechanism instead of the
operator's question:

- **Label with the question, not the machinery.** "Picks the right chart?" beats "Selection ·
  deterministic scorer". Every label passes the cold-read test.
- **Every action button sits on the thing it acts on**, scoped per item or per type. No
  global toolbars far from the data they operate on.
- **A button implies cost.** Free, instant checks re-run automatically on edit; anything that
  costs is labelled verb plus cost — "Redraw all 6 · ~10¢ · 1 min".
- **The artifact under improvement is visible, front and center**, at full size — not
  summarized in a table with the real thing buried in a detail view.
- **Two screens, maximum**, usable after weeks away with zero relearning.
