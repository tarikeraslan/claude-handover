#!/usr/bin/env bash
# Pre-compact hook: Extract transcript before compaction destroys context.
# Receives JSON on stdin with: session_id, transcript_path, cwd, trigger
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [[ -z "$SESSION_ID" || -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  exit 0
fi

HANDOVER_DIR="$HOME/.claude/handover/$SESSION_ID"
mkdir -p "$HANDOVER_DIR"

# Extract condensed transcript from JSONL
{
  echo "# Session Transcript (Condensed)"
  echo "- Session: $SESSION_ID"
  echo "- CWD: $CWD"
  echo "- Extracted: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""

  # Process each line of the JSONL transcript
  jq -r '
    if .type == "human" then
      "## User\n" + (
        if (.message | type) == "array" then
          [.message[] | select(.type == "text") | .text] | join("\n")
        elif (.message | type) == "string" then
          .message
        else
          ""
        end
      ) + "\n"
    elif .type == "assistant" then
      "## Assistant\n" + (
        if (.message | type) == "object" and (.message.content | type) == "array" then
          [.message.content[] |
            if .type == "text" then
              .text
            elif .type == "tool_use" then
              "**Tool: " + .name + "**" + (
                if .name == "Read" then " -> " + (.input.file_path // "?")
                elif .name == "Write" then " -> " + (.input.file_path // "?")
                elif .name == "Edit" then " -> " + (.input.file_path // "?")
                elif .name == "Glob" then " -> " + (.input.pattern // "?")
                elif .name == "Grep" then " -> " + (.input.pattern // "?")
                elif .name == "Bash" then " -> `" + ((.input.command // "?") | .[0:120]) + "`"
                else ""
                end
              )
            elif .type == "thinking" then
              ""
            else
              ""
            end
          ] | map(select(. != "")) | join("\n") + "\n"
        else
          ""
        end
      )
    elif .type == "system" then
      "## System\n" + (
        if (.message | type) == "string" then .message
        elif (.message | type) == "array" then
          [.message[] | select(.type == "text") | .text] | join("\n")
        else ""
        end
      ) + "\n"
    else
      empty
    end
  ' "$TRANSCRIPT_PATH" 2>/dev/null || echo "(transcript parse failed)"

} > "$HANDOVER_DIR/transcript.md"

# Save metadata
GIT_BRANCH=""
GIT_STATUS=""
if [[ -d "$CWD/.git" ]] || git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || echo "")
  GIT_STATUS=$(git -C "$CWD" status --porcelain 2>/dev/null | head -20 || echo "")
fi

jq -n \
  --arg session_id "$SESSION_ID" \
  --arg cwd "$CWD" \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg git_branch "$GIT_BRANCH" \
  --arg git_status "$GIT_STATUS" \
  --arg transcript_path "$TRANSCRIPT_PATH" \
  '{
    session_id: $session_id,
    cwd: $cwd,
    timestamp: $timestamp,
    git_branch: $git_branch,
    git_status: $git_status,
    transcript_path: $transcript_path
  }' > "$HANDOVER_DIR/metadata.json"

# Write latest session pointer for easy lookup
echo "$SESSION_ID" > "$HOME/.claude/handover/latest"

exit 0
