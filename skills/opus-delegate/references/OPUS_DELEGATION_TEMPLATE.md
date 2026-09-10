# Opus delegation in this repo

Actively look for work worth handing to Opus through the `opus-delegate`
skill — treat it as a standing option, not a last resort. Delegate substantial,
bounded chunks; keep decomposition, integration, and final review here.

## Verification commands

Pass these to a worker with `--allow-tool`, so it can verify its own work:

    --allow-tool '<TEST_COMMAND>'
    --allow-tool '<LINT_COMMAND>'

Worker mode preapproves only `Read`, `Edit`, `Write`, and read-only git. A
verification command that was not allowed comes back *denied*, not passing —
a worker must report that as a blocker. Patterns match the literal command,
so allow every form that might be used (`pytest` and `python -m pytest`).

## Worth delegating

- `<PATH>` — <why: dense logic, well covered by tests, self-contained>

## Do not delegate

- `<PATH>` — <why: generated, migrations, security-sensitive, needs local context>

## Constraints for delegated work

- <e.g. no new dependencies; match existing error-handling style>

Full protocol lives in the `opus-delegate` skill; this file only records what
is specific to this repository.
