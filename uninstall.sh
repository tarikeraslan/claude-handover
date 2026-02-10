#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SKILLS_DIR="$CLAUDE_DIR/skills/post-compact"
HANDOVER_DIR="$CLAUDE_DIR/handover"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "Uninstalling claude-handover..."

# Remove scripts
rm -f "$SCRIPTS_DIR/pre-compact.sh"
rm -f "$SCRIPTS_DIR/post-compact-inject.sh"
rm -f "$SCRIPTS_DIR/session-start.sh"

# Remove skill
rm -rf "$SKILLS_DIR"

# Remove hooks from settings.json
if [[ -f "$SETTINGS_FILE" ]]; then
  if jq -e '.hooks' "$SETTINGS_FILE" &>/dev/null; then
    jq '
      # Remove PreCompact hooks that reference pre-compact.sh
      .hooks.PreCompact = [.hooks.PreCompact[]? | select(
        (.hooks // []) | all(.command != "bash ~/.claude/scripts/pre-compact.sh")
      )] |

      # Remove SessionStart hooks that reference our scripts
      .hooks.SessionStart = [.hooks.SessionStart[]? | select(
        (.hooks // []) | all(
          .command != "bash ~/.claude/scripts/post-compact-inject.sh" and
          .command != "bash ~/.claude/scripts/session-start.sh"
        )
      )] |

      # Clean up empty arrays
      if (.hooks.PreCompact | length) == 0 then del(.hooks.PreCompact) else . end |
      if (.hooks.SessionStart | length) == 0 then del(.hooks.SessionStart) else . end |
      if (.hooks | length) == 0 then del(.hooks) else . end
    ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "  Hooks removed from $SETTINGS_FILE"
  fi
fi

echo "  Scripts removed from $SCRIPTS_DIR"
echo "  Skill removed from $SKILLS_DIR"
echo ""

# Ask about handover data
if [[ -d "$HANDOVER_DIR" ]]; then
  echo "Handover data at $HANDOVER_DIR was preserved."
  echo "To remove it: rm -rf $HANDOVER_DIR"
fi

echo ""
echo "Done. claude-handover has been uninstalled."
