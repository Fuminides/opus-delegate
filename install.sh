#!/usr/bin/env bash

# Install opus-delegate as a personal Claude Code skill.
# For the plugin route instead, see README.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/skills/opus-delegate"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}/opus-delegate"
MODE="symlink"

usage() {
  echo "Usage: $0 [--symlink|--copy] [--force]" >&2
  echo "  --symlink  link ~/.claude/skills/opus-delegate to this checkout (default)" >&2
  echo "  --copy     copy the skill instead, leaving no dependency on this checkout" >&2
  echo "  --force    replace an existing installation" >&2
}

FORCE=0
while (($#)); do
  case "$1" in
    --symlink) MODE="symlink" ;;
    --copy) MODE="copy" ;;
    --force) FORCE=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 64 ;;
  esac
  shift
done

[[ -f "$SRC/SKILL.md" ]] || { echo "Not a complete checkout: $SRC/SKILL.md is missing" >&2; exit 1; }

if [[ -e "$DEST" || -L "$DEST" ]]; then
  ((FORCE)) || { echo "Already installed at $DEST (use --force to replace)" >&2; exit 1; }
  rm -rf "$DEST"
fi

mkdir -p "$(dirname "$DEST")"
if [[ "$MODE" == symlink ]]; then
  ln -s "$SRC" "$DEST"
else
  cp -R "$SRC" "$DEST"
fi
chmod +x "$DEST"/scripts/*.sh

command -v claude >/dev/null || echo "Warning: 'claude' is not on PATH; the wrappers will fail until it is." >&2
echo "Installed opus-delegate ($MODE) at $DEST"
