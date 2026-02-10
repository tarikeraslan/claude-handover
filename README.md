# claude-handover

Never lose context to compaction again.

When Claude Code compacts your conversation, decisions, file changes, and active work state get reduced to a thin summary. `claude-handover` captures the full transcript before compaction and helps you rebuild context after.

## How it works

```
You're working on a complex task
         │
    Context limit hit → Compaction
         │
    ┌────┴────┐
    │ PreCompact hook fires
    │ Transcript saved to ~/.claude/handover/
    └────┬────┘
         │
    ┌────┴────┐
    │ SessionStart(compact) hook fires
    │ Claude is told: "Run /post-compact"
    └────┬────┘
         │
    ┌────┴────┐
    │ /post-compact skill runs
    │ Gap analysis: compacted summary vs full transcript
    │ Sub-agents extract decisions, files, blockers
    │ Creates prescriptive resume-prompt.md
    └────┬────┘
         │
    Next session starts
         │
    ┌────┴────┐
    │ SessionStart hook fires
    │ resume-prompt.md injected as context
    │ Archived after use
    └─────────┘
```

## What you get after compaction

Instead of a vague summary, you get a structured handover document:

- **DO FIRST** - The single most important next action
- **DO NOT TOUCH** - Stable things to leave alone
- **Key decisions** - What was chosen, and *why*
- **Modified files** - Each file with 1-line context
- **Active blockers** - Unresolved issues
- **User preferences** - Your workflow style
- **Task progress** - Checkboxes for done/remaining

## "Doesn't Claude Code already auto-compact?"

Yes, and that's the problem.

Claude Code's built-in compaction keeps you working when the context window fills up. But it's **lossy** - it compresses your entire conversation into a short summary to free up space. That summary captures the gist, not the details:

- "We refactored the auth module" - but which files? What broke along the way?
- "The user prefers async/await" - but what other decisions did we make?
- "There's an open issue with the tests" - which tests? What was the error?

`claude-handover` doesn't replace compaction. It **works alongside it**:

1. **Before** compaction runs, we save the full transcript to disk
2. **After** compaction, Claude runs gap analysis: "what do I know from the summary vs. what's in the full transcript?"
3. The gaps get filled into a structured handover doc with concrete next actions

Think of it this way: compaction is the parachute (keeps you in the air). Handover is the flight recorder (remembers where you were going).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/tarikeraslan/claude-handover/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/tarikeraslan/claude-handover.git
cd claude-handover
bash install.sh
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/tarikeraslan/claude-handover/main/uninstall.sh | bash
```

Or if you cloned the repo:

```bash
bash uninstall.sh
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (JSON processor) - install with `brew install jq` or `apt install jq`

## What gets installed

| File | Location | Purpose |
|------|----------|---------|
| `pre-compact.sh` | `~/.claude/scripts/` | Extracts transcript before compaction |
| `post-compact-inject.sh` | `~/.claude/scripts/` | Tells Claude to run /post-compact |
| `session-start.sh` | `~/.claude/scripts/` | Injects resume prompt on session start |
| `post-compact/SKILL.md` | `~/.claude/skills/` | Gap analysis + handover creation |

Hooks are merged into `~/.claude/settings.json` without overwriting existing config.

## How transcripts are extracted

The PreCompact hook parses your JSONL session transcript and extracts:

- User messages (your prompts)
- Assistant text responses
- Tool calls with file paths (Read, Write, Edit, Glob, Grep, Bash)
- System messages

Full tool output is excluded - only the tool name and target path are kept. This gives ~95% size reduction while preserving the decision trail.

## Manual usage

If you want to run the handover process manually (without waiting for compaction):

```
/post-compact
```

This works anytime - it reads the latest saved transcript and creates a handover document.

## Data location

All handover data lives in `~/.claude/handover/`:

```
~/.claude/handover/
├── {session-id}/
│   ├── transcript.md    # Condensed session transcript
│   └── metadata.json    # CWD, git branch, timestamp
├── resume-prompt.md     # Next session's context (consumed on use)
├── archive/             # Previously consumed resume prompts
└── latest               # Pointer to most recent session ID
```

## License

MIT
