---
description: Profile this repository for Opus delegation and write an OPUS_DELEGATION.md the agent will actually read
argument-hint: [filename]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git ls-files:*), Bash(ls:*), Bash(find:*)
---

Write a repository-specific Opus delegation profile, then wire it into
`CLAUDE.md` so it is actually loaded.

Target filename: `$1` if given, otherwise `OPUS_DELEGATION.md`, at the
repository root.

## Why the wiring matters

A markdown file sitting in a repository is **not** loaded into context. Only
`CLAUDE.md` is auto-discovered, along with the files it `@`-imports. Without
the import line this file is inert, so step 4 is not optional.

## Step 1 — read the template

Read `${CLAUDE_PLUGIN_ROOT}/templates/OPUS_DELEGATION.md`. It is the skeleton
to fill in, not text to copy verbatim.

## Step 2 — profile the repository

Work out, from the repository itself:

- **Verification commands.** Check `package.json` scripts, `pyproject.toml`,
  `tox.ini`, `Makefile`, `Cargo.toml`, `go.mod`, `.github/workflows/`, and any
  existing `CLAUDE.md`. Convert each into the exact `--allow-tool` string a
  worker needs, e.g. `'Bash(pytest *)'`, `'Bash(npm test *)'`,
  `'Bash(cargo test *)'`. Prefer commands CI actually runs.
- **Worth delegating.** Directories with dense, self-contained logic and real
  test coverage. Name actual paths from this repository.
- **Do not delegate.** Generated code, migrations, vendored dependencies,
  security-sensitive paths, and anything needing context a fresh session lacks.
- **Constraints.** Project-specific rules a worker would otherwise violate —
  dependency policy, error-handling conventions, formatting.

Prefer evidence over guesswork. If the repository does not support a claim,
leave that section out rather than inventing it.

## Step 3 — write the file

Keep it under roughly 40 lines. This file is imported into `CLAUDE.md`, so it
costs context in **every** session in this repository — repo-specific facts
only. Do not restate the general delegation protocol; the skill carries that.

Drop any template section you could not fill with something concrete.

## Step 4 — wire it into CLAUDE.md

The import line is `@<filename>` on its own line.

- **No `CLAUDE.md` at the repository root:** create it with a short heading and
  the import line, then report that you created it.
- **`CLAUDE.md` already exists:** do not edit it yet. Show the user the exact
  one-line addition and where it would go, and ask whether to apply it. If they
  decline, tell them the file is inert until that line is added.
- **The import is already present:** say so and change nothing.

## Step 5 — report

State the file written, whether `CLAUDE.md` was modified or is still pending,
and which verification commands you found. Flag anything you could not
determine so the user can fill it in.
