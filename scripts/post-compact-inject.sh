#!/usr/bin/env bash
# SessionStart(compact) hook: Tell Claude to run /post-compact after compaction.
# Receives JSON on stdin with: session_id, transcript_path, cwd, source
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

LATEST_FILE="$HOME/.claude/handover/latest"
if [[ ! -f "$LATEST_FILE" ]]; then
  exit 0
fi

LATEST_SESSION=$(cat "$LATEST_FILE")
HANDOVER_DIR="$HOME/.claude/handover/$LATEST_SESSION"

if [[ ! -f "$HANDOVER_DIR/transcript.md" ]]; then
  exit 0
fi

cat <<EOF
Context was just compacted. Your previous conversation transcript has been saved.

Saved transcript: $HANDOVER_DIR/transcript.md
Metadata: $HANDOVER_DIR/metadata.json

Run /post-compact now to create a prescriptive handover document that preserves key decisions, active work state, and next actions from the pre-compaction context.
EOF

exit 0
