# Recipe: profile a repository for Opus delegation

Run this when the user asks for `opus-guidelines`, or to set up a repository
for delegation. The result is a section written **into** `AGENTS.md`.

## Why it goes inline

Codex auto-loads `AGENTS.md`, and nothing else. It does **not** resolve
`@file` imports the way Claude Code does — an `@OPUS_DELEGATION.md` line is
read as literal text and the target file is never loaded. So the profile must
be inlined into `AGENTS.md`. A separate file is inert.

## Step 1 — profile the repository

Read `references/OPUS_DELEGATION_TEMPLATE.md` for the shape to fill, then work
out from the repository itself:

- **Verification commands.** Check `package.json` scripts, `pyproject.toml`,
  `tox.ini`, `Makefile`, `Cargo.toml`, `go.mod`, `.github/workflows/`, and any
  existing `AGENTS.md` or `CLAUDE.md`. Convert each into the exact
  `--allow-tool` string a worker needs, e.g. `'Bash(pytest *)'`,
  `'Bash(npm test *)'`. Prefer what CI actually runs.
- **Worth delegating.** Directories with dense, self-contained logic and real
  test coverage. Name actual paths.
- **Do not delegate.** Generated code, migrations, vendored dependencies,
  security-sensitive paths, anything needing context a fresh session lacks.
- **Constraints.** Project rules a worker would otherwise violate.

Prefer evidence over guesswork. Leave a section out rather than inventing it,
and drop any heading you could not fill with something concrete.

## Step 2 — write it into AGENTS.md

Keep the section under roughly 40 lines: `AGENTS.md` is loaded in *every*
Codex session in this repository, so it is permanent context cost. Record
repo-specific facts only — the general delegation protocol is already in this
skill and must not be restated.

- **No `AGENTS.md`:** create it with the profile section.
- **`AGENTS.md` exists:** show the user the exact section and where it would
  go, and ask before editing. It is often hand-curated.
- **A profile section is already present:** offer to update it in place rather
  than appending a second one.

## Step 3 — report

State whether `AGENTS.md` was written or is pending, which verification
commands were found, and anything that could not be determined.
