# opus-delegate

A **Codex** skill for handing bounded work to **Claude Opus** and getting it back
with evidence. Codex keeps decomposition, integration and review; Opus does the
expensive middle chunk. Requires the `claude` CLI — that is the delegation target.

Version 0.1.0.

## What's in the box

| Path | Purpose |
| --- | --- |
| `skills/opus-delegate/SKILL.md` | The policy Codex reads: when to delegate, how to brief, what to demand back. |
| `scripts/opus_worker.sh` | Worker mode — Opus edits files (`acceptEdits`). |
| `scripts/opus_consultant.sh` | Consultant mode — Opus reasons and reports, no edits (`plan`). |
| `references/repo-profile-recipe.md` | Drives the `opus-guidelines` alias. |
| `references/OPUS_DELEGATION_TEMPLATE.md` | Skeleton for a repo's delegation notes. |
| `tests/test_scripts.sh` | Wrapper tests against a stub `claude`. Offline, free. |

## Install

```bash
git clone https://github.com/Fuminides/opus-delegate
cd opus-delegate && ./install.sh      # --copy to not depend on the checkout
```

Or with Codex's own installer:

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo Fuminides/opus-delegate --path skills/opus-delegate
```

Either way it lands in `$CODEX_HOME/skills/opus-delegate` (default `~/.codex`).
**Restart Codex afterwards.** Requires Bash, the `claude` CLI, a UUID source
(`/proc`, `uuidgen`, or `python3`), and GNU `timeout` only if you use `--timeout`.

## Usage

Task on **stdin**, target repo via `--cwd`:

```bash
printf '%s\n' "$TASK" | ~/.codex/skills/opus-delegate/scripts/opus_worker.sh medium \
  --cwd /path/to/repo --timeout 300 --allow-tool 'Bash(pytest *)'
```

Effort is a bare word (`low`|`medium`|`high`|`xhigh`|`max`, default `xhigh`).
Other flags: `--resume SESSION_ID`, `--output-format text|json|stream-json`,
`--session-file FILE`, repeatable `--allow-tool`.

In Codex you normally just ask — the skill fires on its own. Type
`opus-guidelines` to profile the current repo and write its delegation notes
into `AGENTS.md`.

## Tips

- **Always pass your test command** with `--allow-tool`. Worker mode preapproves
  only `Read`, `Edit`, `Write` and read-only git. Anything else is *denied, not
  passing* — a worker must report that as a blocker, so don't take "complete" on faith.
- **Use consultant mode for opinions**, worker mode only when files must change.
- **Notes go inline in `AGENTS.md`.** Codex does not resolve `@file` imports, so
  pointing at a separate file leaves it unread. Keep it short — it loads every session.
- **A timeout or `partial`/`blocked` means unfinished**, with a possibly half-edited
  tree. Inspect the diff, then resume with `--resume` or finish locally.
- **Use a Git worktree** for risky or broad changes. A fresh worktree carries none
  of your uncommitted work — transfer what the task needs deliberately.
- Logs land in `${XDG_STATE_HOME:-$HOME/.local/state}/opus-delegate` and contain
  task output. Delete them when done.

## Check it works

```bash
bash tests/test_scripts.sh                                   # → script tests passed
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py .
```

Then confirm Codex sees it — after restarting, ask it to list its skills;
`opus-delegate` should appear. A live smoke test:

```bash
printf 'Reply with exactly: DELEGATION OK\n' | \
  ~/.codex/skills/opus-delegate/scripts/opus_consultant.sh low --cwd .
```

## License

MIT — see [LICENSE](LICENSE).
