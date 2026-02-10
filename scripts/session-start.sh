#!/usr/bin/env bash
# SessionStart(startup|resume) hook: Inject resume-prompt.md if it exists.
set -euo pipefail

RESUME_FILE="$HOME/.claude/handover/resume-prompt.md"

if [[ ! -f "$RESUME_FILE" ]]; then
  exit 0
fi

ARCHIVE_DIR="$HOME/.claude/handover/archive"
mkdir -p "$ARCHIVE_DIR"

# Output resume prompt as context for Claude
cat "$RESUME_FILE"

# Archive after injection
mv "$RESUME_FILE" "$ARCHIVE_DIR/$(date +%Y%m%d-%H%M%S).md"

exit 0
