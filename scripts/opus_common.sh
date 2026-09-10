#!/usr/bin/env bash

# Shared, deliberately small command-line handling for the two wrappers.
set -euo pipefail
umask 077

EFFORT="xhigh"
EFFORT_SET=0
REPOSITORY_CWD="."
TIMEOUT_SECONDS=""
RESUME_SESSION=""
OUTPUT_FORMAT="json"
SESSION_FILE=""
SESSION_ID=""
SESSION_LOG=""
declare -a EXTRA_ALLOWED_TOOLS=()

usage() {
  echo "Usage: $0 [effort] [--cwd DIR] [--timeout SECONDS] [--resume SESSION_ID] [--allow-tool TOOL] [--output-format text|json|stream-json] [--session-file FILE]" >&2
}

while (($#)); do
  case "$1" in
    low|medium|high|xhigh|max)
      ((EFFORT_SET == 0)) || { usage; exit 64; }
      EFFORT="$1"
      EFFORT_SET=1
      ;;
    --cwd|-C)
      (($# >= 2)) || { usage; exit 64; }
      REPOSITORY_CWD="$2"; shift
      ;;
    --timeout)
      (($# >= 2)) || { usage; exit 64; }
      TIMEOUT_SECONDS="$2"; shift
      [[ "$TIMEOUT_SECONDS" =~ ^[1-9][0-9]*([.][0-9]+)?$ ]] || { echo "Invalid timeout: $TIMEOUT_SECONDS" >&2; exit 64; }
      ;;
    --resume)
      (($# >= 2)) || { usage; exit 64; }
      RESUME_SESSION="$2"; shift
      [[ "$RESUME_SESSION" =~ ^[a-zA-Z0-9-]+$ ]] || { echo "Invalid session ID" >&2; exit 64; }
      ;;
    --output-format)
      (($# >= 2)) || { usage; exit 64; }
      OUTPUT_FORMAT="$2"; shift
      [[ "$OUTPUT_FORMAT" == text || "$OUTPUT_FORMAT" == json || "$OUTPUT_FORMAT" == stream-json ]] || { echo "Invalid output format: $OUTPUT_FORMAT" >&2; exit 64; }
      ;;
    --session-file)
      (($# >= 2)) || { usage; exit 64; }
      SESSION_FILE="$2"; shift
      ;;
    --allow-tool)
      (($# >= 2)) || { usage; exit 64; }
      EXTRA_ALLOWED_TOOLS+=("$2"); shift
      ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 64 ;;
  esac
  shift
done

PROMPT="$(cat)"
[[ -n "${PROMPT//[[:space:]]/}" ]] || { echo "Prompt must not be empty" >&2; exit 64; }
[[ -d "$REPOSITORY_CWD" ]] || { echo "Repository cwd is not a directory: $REPOSITORY_CWD" >&2; exit 64; }

command -v claude >/dev/null || { echo "claude is not installed or not on PATH" >&2; exit 127; }
if [[ -n "$TIMEOUT_SECONDS" ]]; then
  command -v timeout >/dev/null || { echo "GNU timeout is required for --timeout" >&2; exit 127; }
fi

if [[ -n "$RESUME_SESSION" ]]; then
  SESSION_ID="$RESUME_SESSION"
else
  SESSION_ID="$(cat /proc/sys/kernel/random/uuid)"
fi
if [[ -z "$SESSION_FILE" ]]; then
  SESSION_DIR="${XDG_STATE_HOME:-${HOME:?}/.local/state}/opus-delegate"
  mkdir -p "$SESSION_DIR"
  SESSION_FILE="$(mktemp "$SESSION_DIR/$SESSION_ID.XXXXXX.log")"
else
  mkdir -p "$(dirname "$SESSION_FILE")"
  # Resolve before changing to the target repository.
  SESSION_FILE="$(cd "$(dirname "$SESSION_FILE")" && pwd)/$(basename "$SESSION_FILE")"
fi
SESSION_LOG="$SESSION_FILE"
printf '# session_id=%s\n' "$SESSION_ID" >>"$SESSION_LOG"
printf 'Opus session: %s\nLog: %s\n' "$SESSION_ID" "$SESSION_LOG" >&2

run_and_preserve() {
  local status
  # Wait for tee to flush before returning, preserving the command's exit code.
  set +e
  "$@" 2>&1 | tee -a "$SESSION_LOG"
  local -a statuses=("${PIPESTATUS[@]}")
  set -e
  status="${statuses[0]}"
  (( status != 0 )) || status="${statuses[1]}"
  printf '# exit_status=%s\n' "$status" >>"$SESSION_LOG"
  return "$status"
}
