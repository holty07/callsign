---
description: Work a roadmap milestone to completion, one commit per checklist item
---

Read `CLAUDE.md` and `docs/ROADMAP.md`.

Work milestone **$ARGUMENTS** to completion. Rules for this run:

- One checklist item per commit, using conventional commit format.
- Run `godot --headless --path . --import` then the gdUnit4 suite before each commit.
- Do not start work belonging to any other milestone, even if it seems trivial.
- If a checklist item is ambiguous, or requires a judgement about how the game
  should feel, stop and ask rather than guessing.
- Tick items off in `docs/ROADMAP.md` as you complete them, in the same commit.
- If you think of work that isn't in this milestone, append it to `docs/BACKLOG.md`
  instead of doing it.

Report at the end: what you completed, what you skipped and why, and whether the
milestone's "Done when" condition is met.
