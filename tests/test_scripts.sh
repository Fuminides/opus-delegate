#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$ROOT/skills/opus-delegate"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir "$TMP/work"
LOG="$TMP/claude.log"
cat >"$TMP/claude" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
printf '%q ' "$@" >"${FAKE_LOG:?}"
printf ' cwd=%q' "$PWD" >>"${FAKE_LOG:?}"
printf '\n' >>"${FAKE_LOG:?}"
[[ "${FAKE_SLEEP:-0}" == 0 ]] || sleep "$FAKE_SLEEP"
printf '{"session_id":"sid-123","result":"ok"}\n'
exit "${FAKE_EXIT:-0}"
FAKE
chmod +x "$TMP/claude"
export PATH="$TMP:$PATH" FAKE_LOG="$LOG"
export XDG_STATE_HOME="$TMP/state"

output="$(env -u FAKE_SLEEP bash -c "printf '%s' 'fix - leading prompt' | '$SKILL_DIR/scripts/opus_worker.sh' medium --cwd '$TMP/work' --resume sid-old --allow-tool 'Bash(npm test *)'")"
grep -q 'sid-123' <<<"$output"
grep -q -- '--resume sid-old' "$LOG"
grep -q -- 'npm\\ test' "$LOG"
grep -q -- "$(printf '%q' "$TMP/work")" "$LOG"

if printf '   \n' | "$SKILL_DIR/scripts/opus_consultant.sh" >/dev/null 2>&1; then exit 1; fi
if printf 'x' | "$SKILL_DIR/scripts/opus_worker.sh" bogus >/dev/null 2>&1; then exit 1; fi
if printf 'x' | "$SKILL_DIR/scripts/opus_worker.sh" --cwd "$TMP/missing" >/dev/null 2>&1; then exit 1; fi

export FAKE_SLEEP=2
if printf x | "$SKILL_DIR/scripts/opus_consultant.sh" --cwd "$TMP/work" --timeout 1 >/dev/null 2>&1; then exit 1; fi

session_file="$TMP/custom.jsonl"
unset FAKE_SLEEP
printf '%s' '-starts-with-dash' | "$SKILL_DIR/scripts/opus_consultant.sh" --cwd "$TMP/work" --session-file "$session_file" --allow-tool Read >/dev/null
grep -q 'session_id=' "$session_file"
grep -q -- 'Read' "$LOG"
grep -q -- '--session-id' "$LOG"

# Exact failures and artifact persistence, including repeated resume runs.
set +e
printf x | FAKE_EXIT=23 "$SKILL_DIR/scripts/opus_worker.sh" --session-file "$session_file" >/dev/null 2>&1
status=$?
set -e
[[ "$status" == 23 ]]
grep -q '# exit_status=23' "$session_file"
[[ "$(grep -c '# session_id=' "$session_file")" == 2 ]]
set +e
printf x | FAKE_SLEEP=2 "$SKILL_DIR/scripts/opus_worker.sh" --timeout 1 --session-file "$TMP/timeout.log" >/dev/null 2>&1
status=$?
set -e
[[ "$status" == 124 ]]
grep -q '# session_id=' "$TMP/timeout.log"
grep -q '# exit_status=124' "$TMP/timeout.log"
if printf x | "$SKILL_DIR/scripts/opus_worker.sh" xhigh medium >/dev/null 2>&1; then exit 1; fi
if printf x | "$SKILL_DIR/scripts/opus_worker.sh" --resume '../escape' >/dev/null 2>&1; then exit 1; fi
printf '%s' '-prompt' | "$SKILL_DIR/scripts/opus_consultant.sh" --output-format stream-json >/dev/null
# Verbose must be an option, before the argument terminator and prompt.
grep -q -- '--verbose -- -prompt' "$LOG"
(cd "$TMP" && printf x | "$SKILL_DIR/scripts/opus_worker.sh" --cwd "$TMP/work" --session-file relative.log >/dev/null)
[[ -f "$TMP/relative.log" && ! -f "$TMP/work/relative.log" ]]
echo 'script tests passed' 
