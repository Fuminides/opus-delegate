#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/opus_common.sh"

run_consultant() {
  local -a command=(claude -p --model opus --effort "$EFFORT" --output-format "$OUTPUT_FORMAT" --permission-mode plan --permission-prompts none)
  if ((${#EXTRA_ALLOWED_TOOLS[@]})); then command+=(--allowedTools "${EXTRA_ALLOWED_TOOLS[@]}"); fi
  if [[ -n "$RESUME_SESSION" ]]; then command+=(--resume "$RESUME_SESSION"); else command+=(--session-id "$SESSION_ID"); fi
  if [[ "$OUTPUT_FORMAT" == stream-json ]]; then command+=(--verbose); fi
  command+=(-- "$PROMPT")
  if [[ -n "$TIMEOUT_SECONDS" ]]; then timeout --kill-after=5s "$TIMEOUT_SECONDS" "${command[@]}"; else "${command[@]}"; fi
}
(cd "$REPOSITORY_CWD" && run_and_preserve run_consultant)
