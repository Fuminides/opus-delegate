# opus-delegate

**Codex orchestrates. Opus implements. Use both subscriptions from one Codex session.**

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

### Let Codex reach the network

The wrappers call the Anthropic API, but Codex's `workspace-write` sandbox
blocks network access by default, so delegation fails from inside Codex until
you allow it in `~/.codex/config.toml`:

```toml
[sandbox_workspace_write]
network_access = true
```

Logs fall back to `$TMPDIR` when the sandbox makes `~/.local/state` read-only.
To keep them in one place instead, also add
`writable_roots = ["~/.local/state"]` to that section.

## Usage

Type
`opus-guidelines` to profile the current repo and write its delegation notes
into `AGENTS.md`.

Then, the skill fires on its own. 

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

### Authentication and subscriptions

opus-delegate does not access, store, proxy, or modify Claude credentials.

Delegated tasks are executed through Anthropic's official locally installed
`claude` CLI. Authentication and usage limits remain entirely managed by
Claude Code and the user's Anthropic account.

Likewise, the skill does not modify Codex authentication or attempt to
circumvent Codex usage limits.

## License

MIT — see [LICENSE](LICENSE).
