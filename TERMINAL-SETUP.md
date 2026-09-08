# Terminal setup — Claude Code in Kitty on CachyOS

Fish syntax throughout.

## 1. Install Claude Code

The native installer is the recommended path on Linux. It drops a standalone binary
at `~/.local/bin/claude` and auto-updates in the background — no Node.js needed.

```fish
curl -fsSL https://claude.ai/install.sh | bash
```

Do **not** run this with `sudo`. It installs into your home directory by design;
with sudo it lands in root's home and `claude` won't be found for your user.

## 2. Fix PATH for fish

This is the step that trips people up. The installer appends PATH configuration to
`~/.bashrc` or `~/.zshrc` — it doesn't know about fish. Add the path properly:

```fish
fish_add_path ~/.local/bin
```

`fish_add_path` writes to your universal variables, so it persists across sessions
and survives config rewrites. Then:

```fish
rehash
claude --version
claude doctor
```

`claude doctor` confirms the binary, the update mechanism, and flags any PATH
conflicts from a stray npm install.

## 3. Log in

```fish
cd ~/dev/callsign
claude
```

On first run it prints an auth URL. Kitty makes URLs clickable with **Ctrl+Shift+E**,
or Ctrl-click. Sign in with the Claude account you want billed — this is separate
from your GitHub identity and unrelated to holty07.

## 4. Drop in the config

From this bundle, copy into the repo:

```fish
mkdir -p ~/dev/callsign/.claude/commands
cp commands/*.md ~/dev/callsign/.claude/commands/
cp settings.json ~/dev/callsign/.claude/settings.json
```

`settings.json` pre-approves the commands Claude will run constantly — headless
Godot, read-only git, `gh` status checks — so you aren't approving the same test
run forty times. It denies force-push, hard reset, `rm -rf`, and reading `.env`.

Default permission mode is `acceptEdits`: Claude edits files freely but still asks
before running commands outside the allowlist. Reasonable for solo work on a repo
that's fully version-controlled. Switch modes mid-session with **Shift+Tab**.

Commit `.claude/` to the repo — it's project configuration, not personal state.

## 5. Verify before session 1

```fish
cd ~/dev/callsign
git remote -v          # git@github-holty07:holty07/callsign.git
git log -1 --format='%an <%ae>'
godot --version        # 4.7.x
claude doctor
```

All four correct? Start the session. The prompts are in `KICKOFF.md`.

## Kitty notes

- **Ctrl+Shift+E** — open URLs from the scrollback without a mouse.
- **Shift+Tab** in Claude Code cycles permission modes; Kitty passes it through fine.
- If you want a bell when Claude finishes a long run, Kitty's `enable_audio_bell yes`
  plus a Notification hook is the tidiest combination.
- Long sessions produce a lot of scrollback. `scrollback_lines 10000` in
  `~/.config/kitty/kitty.conf` saves you losing earlier output.

## Useful in-session commands

| Command | What it does |
|---|---|
| `/milestone M1` | Work a roadmap milestone (custom) |
| `/check` | Run tests, report failures, change nothing (custom) |
| `/asset <url>` | Import an asset with licence vetting (custom) |
| `/context` | See what's loaded and how full the window is |
| `/compact` | Summarise and free context mid-session |
| `/memory` | View and edit what CLAUDE.md contributed |
| `Esc` | Interrupt Claude mid-action |
| `Shift+Tab` | Cycle permission mode |

## If something goes wrong

- **`command not found: claude`** — `fish_add_path ~/.local/bin` then `rehash`.
- **Two installs fighting** — if you ever installed via npm, remove it; an older
  binary earlier in PATH will win. `claude doctor` reports this.
- **Godot not found in a session** — Desktop and CLI both inherit PATH at launch.
  Restart Kitty after installing Godot.
