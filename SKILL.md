---
name: opus-delegate
description: Delegate substantial implementation, debugging, or independent review to Claude Opus when it can reduce Astra's token use while preserving solution quality. Do not use for trivial tasks or work adequately handled by a cheaper Codex subagent.
---

# Opus delegation

The aim is to save Astra tokens while retaining Astra's strengths in reasoning,
architecture, and judgment. Use Opus for substantial, bounded implementation or
independent analysis; keep Astra responsible for task decomposition, integration,
critical review, and final validation.

Judge savings across the whole task, including briefing, duplicated context,
review, and rework. Delegate when those costs are likely lower than Astra doing
the work directly. Give focused context and request concise evidence instead of
raw logs; do not duplicate the delegated implementation in Astra. Token savings
must not reduce correctness, necessary verification, or completion of the user's
request.

Invoke:

    <skill-dir>/scripts/opus_worker.sh

for implementation, and

    <skill-dir>/scripts/opus_consultant.sh

for consulting/debugging. Resolve `<skill-dir>` to the skill's absolute
directory, and run the script with the target repository as its working
directory. Provide the complete task through stdin. This keeps delegation
portable when Astra is working in another repository.

Use a compact brief containing:

- objective and relevant repository/context;
- target repository path and files or symbols in scope;
- ownership boundaries (what Opus may edit and what it must leave alone);
- constraints and acceptance criteria; and
- verification commands and the evidence to report.

Do not make Opus rediscover context that Astra already has, but include enough
context for it to work independently.

## When to use Opus

Prefer Opus for substantial implementation it can carry through reliably, or
when independent reasoning would materially improve confidence. Use a cheaper
Codex subagent for routine bounded work, and keep small tasks local when
delegation overhead would exceed the benefit.

Other situations where you might find Opus useful:
- difficult debugging where the root cause is unclear;
- adversarial review of a proposed implementation;
- situations where your own diagnosis is uncertain;
- bugs for which an earlier attempted fix failed;
- research-oriented or algorithmically difficult implementation questions that you had trouble understanding.

Do not use Opus for:
- simple file discovery;
- grep/search operations;
- routine tests;
- straightforward mechanical changes;
- tasks already adequately handled by a cheaper Codex subagent.

## Delegation protocol

When you need its opinion on something, treat Opus as an independent expert, not an authority.

Give it sufficient context to solve the task, but do not bias it with your
preferred answer when independent judgement is desirable.

For implementation work, ask Opus to return:
1. status (complete, partial, or blocked);
2. concise summary of changes and relevant files/symbols;
3. verification commands actually run and their results;
4. remaining work, blockers, and uncertainties.

For consultation or debugging, ask Opus to return:
1. conclusion and independently derived reasoning/evidence;
2. relevant files and symbols;
3. recommended action;
4. uncertainties, competing explanations, and how to distinguish them.

For debugging, ask Opus to independently derive the root cause and attempt
to falsify plausible competing hypotheses.

For review, provide the proposed implementation or current diff and ask
Opus to actively search for correctness problems, regressions and missing
edge cases. Require each finding to include severity, file and line or symbol
location, concrete evidence, and a recommended fix; require an explicit
statement when no findings were found.

After receiving the result:
- inspect its evidence yourself;
- reconcile it with your own findings and other agents;
- do not blindly implement its recommendation;
- retain responsibility for the final decision and verification.

Treat a nonzero exit, timeout, interruption, or `partial`/`blocked` report as
incomplete work. Inspect the working tree and diff, preserve useful partial
changes, and either resume with a brief that states what remains or finish the
task locally. Do not report completion unless the acceptance criteria and
verification have been satisfied.

Before delegation, inspect the target working tree and preserve unrelated user
changes. In a shared checkout, give Opus explicit file ownership and do not
have Astra or another agent edit those files concurrently. Use an isolated Git
worktree for concurrent, risky, or broad changes when practical; integrate the
result only after reviewing its diff and verifying it in the target repository.
A new worktree does not include uncommitted changes: explicitly transfer any
changes needed for the task without overwriting unrelated work.

## Instructions to use the claude command

Both wrappers read the prompt from stdin and default to `xhigh` effort and JSON
output. Pass the target repository explicitly with `--cwd`; the wrapper runs
Opus from that directory. Resolve `<skill-dir>` to the skill's absolute path.
For example:

    printf '%s\n' "$TASK" | <skill-dir>/scripts/opus_worker.sh medium \
      --cwd /path/to/repository --timeout 300 \
      --allow-tool 'Bash(npm test *)'

Supported options are `low`, `medium`, `high`, `xhigh`, or `max` effort;
`--cwd DIR`; `--timeout SECONDS`; `--resume SESSION_ID`;
`--output-format text|json|stream-json`; `--session-file FILE`; and repeated
`--allow-tool TOOL`.
Use `--resume` with the returned session identifier when continuing an
interrupted or partial delegation. Keep the target repository in `--cwd`, and
keep the skill path absolute even when the current shell directory differs.

`--allow-tool` adds task-specific preapprovals; it does not define the entire
available tool set or bypass permission rules. Both modes deny requests that
would require a permission prompt. Workers must report denied verification
commands as blockers, never as passing checks. Consultant mode uses plan
permissions; use worker mode when the task requires edits.

The wrappers require Bash, Claude Code, and Linux (`/proc` for UUID generation;
GNU `timeout` when `--timeout` is used). No timeout is imposed unless specified.
They announce a session ID and log path on stderr before launching Claude.
Each run gets a separate log under `${XDG_STATE_HOME:-$HOME/.local/state}/opus-delegate`,
containing the session ID, emitted stdout/stderr, and exit status. Use
`--session-file FILE` to append to a chosen log; relative paths resolve against
the caller's directory. Logs contain task output; remove them when no longer needed.

Claude output and diagnostics are combined on stdout and in the log; the log
also contains wrapper metadata and is not a standalone JSON document. For
partial progress during long runs, choose `--output-format stream-json`.
On timeout, the wrapper sends TERM then escalates to KILL after five seconds;
exit 124 normally indicates timeout (forced termination can return 137).
A saved ID permits `--resume` only if Claude persisted the session before the
interruption. Inspect partial edits before resuming, and do not retry unchanged
permission or environment failures repeatedly.
