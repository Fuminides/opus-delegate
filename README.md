# opus-delegate

A [Claude Code](https://claude.com/claude-code) skill that lets an agent hand
substantial work to Claude Opus in a separate headless session, and two shell
wrappers that make those handoffs reliable.

The point is cost, not capability. A cheap or heavily-loaded agent keeps what it
is good at — decomposing the task, integrating the result, reviewing it — and
pays Opus prices only for the bounded chunk in the middle. The skill spells out
when that trade is worth making and, just as importantly, when it isn't.

## What's in the box

| Path | Purpose |
| --- | --- |
| `skills/opus-delegate/SKILL.md` | The delegation policy the calling agent reads: when to delegate, how to brief, what to demand back. |
| `skills/opus-delegate/scripts/opus_worker.sh` | Worker mode — Opus edits files. `acceptEdits` permissions. |
| `skills/opus-delegate/scripts/opus_consultant.sh` | Consultant mode — Opus reasons and reports. `plan` permissions, no edits. |
| `skills/opus-delegate/scripts/opus_common.sh` | Shared argument parsing, session IDs, logging. |
| `commands/opus-guidelines.md` | `/opus-delegate:opus-guidelines` — profiles a repo and writes its `OPUS_DELEGATION.md`. |
| `templates/OPUS_DELEGATION.md` | The skeleton that command fills in, if you'd rather write it by hand. |
| `tests/test_scripts.sh` | Wrapper tests against a stub `claude` binary. No API calls, no cost. |

## Install

**As a plugin** (recommended — no files to place by hand):

```
/plugin marketplace add Fuminides/opus-delegate
/plugin install opus-delegate@opus-delegate
```

**As a personal skill**, if you'd rather keep a checkout you can edit:

```bash
git clone https://github.com/Fuminides/opus-delegate
cd opus-delegate
./install.sh            # symlinks ~/.claude/skills/opus-delegate to this checkout
./install.sh --copy     # or copy it, if you don't want the dependency
```

`--force` replaces an existing install. `CLAUDE_SKILLS_DIR` overrides the target
directory.

**To try it for one session without installing anything:**

```bash
claude --plugin-dir /path/to/opus-delegate
```

## Requirements

- Bash and the `claude` CLI on `PATH`
- A UUID source: `/proc`, `uuidgen`, or `python3`
- GNU `timeout`, but only if you use `--timeout` (on macOS: `brew install coreutils`)

## Usage

Both wrappers take the task on **stdin** and the target repository via `--cwd`.
Nothing is read from the current shell directory, so delegation works the same
whichever repo the caller happens to be sitting in.

```bash
printf '%s\n' "$TASK" | skills/opus-delegate/scripts/opus_worker.sh medium \
  --cwd /path/to/repository \
  --timeout 300 \
  --allow-tool 'Bash(npm test *)'
```

Installed as a plugin, the skill directory is
`${CLAUDE_PLUGIN_ROOT}/skills/opus-delegate`; installed as a personal skill it is
`~/.claude/skills/opus-delegate`.

### Options

| Option | Meaning |
| --- | --- |
| `low`\|`medium`\|`high`\|`xhigh`\|`max` | Reasoning effort, given as a bare word. Default `xhigh`. |
| `--cwd DIR` | Repository Opus runs in. Default `.` — set it explicitly. |
| `--timeout SECONDS` | TERM, then KILL five seconds later. Exit 124 (or 137 if forced). |
| `--resume SESSION_ID` | Continue an interrupted or partial delegation. |
| `--output-format text\|json\|stream-json` | Default `json`. Use `stream-json` to watch a long run progress. |
| `--session-file FILE` | Append to a log you choose instead of the default location. |
| `--allow-tool TOOL` | Extra preapproval. Repeatable. |

### Worker vs. consultant

**Worker** runs with `--permission-mode acceptEdits` and preapproves `Read`,
`Edit`, `Write`, and read-only `git diff`/`status`/`log`. That deliberately
excludes your test runner: pass it yourself with `--allow-tool 'Bash(pytest *)'`
or whatever the project actually uses, so the preapproval matches the repo
rather than a guess baked into the script.

**Consultant** runs with `--permission-mode plan` and preapproves nothing. It
reads, reasons, and reports; it does not touch the working tree.

Both run with `--permission-prompts none`, so anything that *would* prompt is
denied instead of hanging. This has a consequence worth internalizing: a
verification command Opus wasn't allowed to run comes back denied, not passing.
The skill instructs Opus to report those as blockers, and instructs the caller
not to take a "complete" status on faith.

### Logs

Each run writes a log under
`${XDG_STATE_HOME:-$HOME/.local/state}/opus-delegate`, holding the session ID,
combined stdout/stderr, and the exit status. The session ID and log path are
announced on stderr before Claude launches.

Logs contain task output, which means they contain whatever your code and
prompts contained. Delete them when you're done. The wrappers set `umask 077`,
so they're owner-readable only.

The log is not a standalone JSON document — it interleaves Claude's output with
wrapper metadata lines (`# session_id=`, `# exit_status=`).

## Making the agent reach for it

Installing the skill makes delegation *available*. It doesn't make the agent
*look* for it, and it can't tell the worker how to verify anything in your
project. That's what a per-repo profile is for:

```
/opus-delegate:opus-guidelines
```

The command reads your repo — `package.json`, `pyproject.toml`, `Makefile`,
`.github/workflows/`, the directory layout — and writes an `OPUS_DELEGATION.md`
recording what only this repo knows: the test and lint commands as ready-to-paste
`--allow-tool` strings, which directories are worth delegating, which are
off-limits, and any constraints a fresh Opus session would otherwise violate.
Pass a different filename as an argument if you prefer one.

**A markdown file in your repo is not loaded into context.** Only `CLAUDE.md` is
auto-discovered, along with the files it `@`-imports. So the profile is inert
until `CLAUDE.md` contains:

```markdown
@OPUS_DELEGATION.md
```

The command creates `CLAUDE.md` with that line if you don't have one. If you do,
it shows you the addition and asks first, rather than editing a file you may
have curated deliberately.

Keep the profile short — it is imported into `CLAUDE.md`, so you pay for it in
every session in that repo. Repo-specific facts only; the general delegation
protocol already lives in the skill. `templates/OPUS_DELEGATION.md` is the
starting point if you'd rather fill it in yourself.

## Handling failure

A nonzero exit, a timeout, or a `partial`/`blocked` report all mean the same
thing: **the work is not done**, and the working tree may be half-edited. The
skill's protocol is to inspect the diff, keep what's useful, and either resume
with a brief describing what remains or finish locally.

`--resume` only works if Claude persisted the session before the interruption,
so treat a saved ID as a maybe rather than a guarantee.

For concurrent, risky, or broad changes, give Opus its own Git worktree. Note
that a fresh worktree does **not** carry your uncommitted changes — transfer
what the task needs, deliberately, without clobbering unrelated work.

## Development

```bash
bash tests/test_scripts.sh
```

The tests stub `claude` with a fake binary that records its arguments, so they
run offline and cost nothing. They cover argument parsing, prompts that begin
with `-`, empty prompts, timeout behavior and exit codes, log persistence across
resumed runs, and relative `--session-file` resolution against the caller's
directory rather than `--cwd`.

CI additionally runs `shellcheck` and rejects CRLF line endings. That last check
is not cosmetic: a CRLF checkout puts `\r` on the shebang and every `set` line,
and the wrappers fail with `set: pipefail: invalid option name`. `.gitattributes`
pins the whole repo to LF — please don't override it.

## License

MIT — see [LICENSE](LICENSE).
