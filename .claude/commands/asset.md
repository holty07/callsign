---
description: Import a third-party asset and record it in the licence ledger
---

Add the asset described by **$ARGUMENTS** to the project.

Steps:

1. Confirm the licence permits redistribution in a GPL-2.0-or-later open-source
   repository. Acceptable: CC0, CC-BY, CC-BY-SA, public domain, or an explicitly
   permissive custom licence.
2. **Refuse** if the licence is unclear, absent, non-commercial only, or restricts
   redistribution of the asset files themselves. Mixamo animations fall in this
   category — see rule 4 in `CLAUDE.md`. Say so plainly rather than proceeding.
3. Place the file under the correct `assets/` subdirectory and run
   `godot --headless --path . --import`.
4. Append a row to `docs/ASSETS.md`: path, source URL, author, licence, date added.
5. If the licence is CC-BY or CC-BY-SA, also add the attribution to the in-game
   credits screen — the ledger alone doesn't satisfy the licence.
6. Commit with `chore(assets):` and nothing else in the commit.

If the asset needs conversion (FBX to glTF, WAV resampling), do that before import
and note the original format in the ledger row.
