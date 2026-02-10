#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SKILLS_DIR="$CLAUDE_DIR/skills/post-compact"
HANDOVER_DIR="$CLAUDE_DIR/handover"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Determine script source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running from repo or via curl
if [[ -f "$SCRIPT_DIR/scripts/pre-compact.sh" ]]; then
  SRC_DIR="$SCRIPT_DIR"
else
  # Downloaded via curl - fetch tarball (no git required)
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT
  curl -fsSL https://github.com/tarikeraslan/claude-handover/archive/refs/heads/main.tar.gz | tar xz -C "$TEMP_DIR" --strip-components=1
  SRC_DIR="$TEMP_DIR"
fi

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed."
  echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

# Check for Claude Code
if [[ ! -d "$CLAUDE_DIR" ]]; then
  echo "Error: ~/.claude directory not found. Is Claude Code installed?"
  exit 1
fi

echo "Installing claude-handover..."

# Create directories
mkdir -p "$SCRIPTS_DIR" "$SKILLS_DIR" "$HANDOVER_DIR/archive"

# Copy scripts
cp "$SRC_DIR/scripts/pre-compact.sh" "$SCRIPTS_DIR/"
cp "$SRC_DIR/scripts/post-compact-inject.sh" "$SCRIPTS_DIR/"
cp "$SRC_DIR/scripts/session-start.sh" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/pre-compact.sh" "$SCRIPTS_DIR/post-compact-inject.sh" "$SCRIPTS_DIR/session-start.sh"

# Copy skill
cp "$SRC_DIR/skills/post-compact/SKILL.md" "$SKILLS_DIR/"

# Merge hooks into settings.json
HOOKS_JSON='{
  "PreCompact": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "bash ~/.claude/scripts/pre-compact.sh",
          "timeout": 30
        }
      ]
    }
  ],
  "SessionStart": [
    {
      "matcher": "compact",
      "hooks": [
        {
          "type": "command",
          "command": "bash ~/.claude/scripts/post-compact-inject.sh",
          "timeout": 5
        }
      ]
    },
    {
      "matcher": "startup|resume",
      "hooks": [
        {
          "type": "command",
          "command": "bash ~/.claude/scripts/session-start.sh",
          "timeout": 10
        }
      ]
    }
  ]
}'

if [[ -f "$SETTINGS_FILE" ]]; then
  # Merge hooks into existing settings (preserves all other config)
  EXISTING=$(cat "$SETTINGS_FILE")

  if echo "$EXISTING" | jq -e '.hooks' &>/dev/null; then
    # Has existing hooks - deep merge
    echo "$EXISTING" | jq --argjson new_hooks "$HOOKS_JSON" '
      .hooks = (.hooks // {}) * $new_hooks
    ' > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  else
    # No hooks yet - add them
    echo "$EXISTING" | jq --argjson hooks "$HOOKS_JSON" '.hooks = $hooks' > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  fi
else
  # No settings file - create one
  echo "{}" | jq --argjson hooks "$HOOKS_JSON" '.hooks = $hooks' > "$SETTINGS_FILE"
fi

echo ""
echo "Installed:"
echo "  Scripts:  $SCRIPTS_DIR/pre-compact.sh"
echo "            $SCRIPTS_DIR/post-compact-inject.sh"
echo "            $SCRIPTS_DIR/session-start.sh"
echo "  Skill:    $SKILLS_DIR/SKILL.md"
echo "  Hooks:    merged into $SETTINGS_FILE"
echo "  Data:     $HANDOVER_DIR/"
echo ""
echo "Done. Context handover is now active in Claude Code."
echo "When compaction happens, you'll be prompted to run /post-compact."
