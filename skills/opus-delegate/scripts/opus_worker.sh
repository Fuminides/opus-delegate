#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/opus_common.sh"

DEFAULT_ALLOWED_TOOLS=(
    "Read" "Edit" "Write" \
    "Bash(git diff *)" \
    "Bash(git status *)" \
    "Bash(git log *)"
)
run_worker() {
  local -a command=(claude -p --model opus --permission-mode acceptEdits --permission-prompts none --effort "$EFFORT" --output-format "$OUTPUT_FORMAT" --allowedTools)
  command+=("${DEFAULT_ALLOWED_TOOLS[@]}" "${EXTRA_ALLOWED_TOOLS[@]}")
  if [[ -n "$RESUME_SESSION" ]]; then command+=(--resume "$RESUME_SESSION"); else command+=(--session-id "$SESSION_ID"); fi
  if [[ "$OUTPUT_FORMAT" == stream-json ]]; then command+=(--verbose); fi
  command+=(-- "$PROMPT")
  if [[ -n "$TIMEOUT_SECONDS" ]]; then timeout --kill-after=5s "$TIMEOUT_SECONDS" "${command[@]}"; else "${command[@]}"; fi
}
(cd "$REPOSITORY_CWD" && run_and_preserve run_worker)
