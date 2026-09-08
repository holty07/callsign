---
description: Run import and the test suite, report failures only, fix nothing
---

Run, in order:

```fish
godot --headless --path . --import
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/
```

Report **failures only** — do not print passing test names, and do not summarise
what the suite covers.

Do not fix anything. Do not edit any file. If something fails, describe the failure
and what you think is causing it, then stop and wait for me to decide.

If the import step produces errors or warnings, report those too — Godot import
failures often masquerade as test failures further down.
