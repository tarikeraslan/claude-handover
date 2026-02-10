---
name: post-compact
description: Create prescriptive handover after context compaction
user_invocable: true
allowed-tools: Read, Grep, Glob, Task, Write
---

# Post-Compact Handover

You have just been compacted. Your goal is to create a **prescriptive** (not descriptive) handover document that tells a future Claude session exactly what to do, what not to touch, and why.

## Step 1: Self-Assess

List what you currently know from the compacted summary:
- What project/task were you working on?
- What files do you remember modifying?
- What decisions do you remember making?
- What was the last thing you were doing?

Write these down as bullet points. Be honest about gaps.

## Step 2: Find the Saved Transcript

Read `~/.claude/handover/latest` to get the session ID, then read:
- `~/.claude/handover/{session_id}/transcript.md` (the full pre-compaction transcript)
- `~/.claude/handover/{session_id}/metadata.json` (CWD, git branch, timestamp)

If the transcript doesn't exist, skip to Step 5 and create the handover from what you know.

## Step 3: Gap Analysis

Compare what you know (Step 1) vs what the transcript shows. Identify:
- **File paths** mentioned in transcript but whose content you don't remember
- **Decisions** referenced but whose rationale is lost
- **Active work items** and their current state (done, in-progress, blocked)
- **Errors** encountered and solutions applied
- **User preferences** or instructions you may have forgotten

## Step 4: Extract Key Details

Use up to 3 sub-agents (Task tool with subagent_type=Explore) to scan the transcript in parallel:

**Agent 1 - Decisions & Rationale**: Find all instances where a choice was made between alternatives. Extract the choice AND why.

**Agent 2 - Files & Errors**: Find all file paths that were modified (Write/Edit tool calls). Find all errors and their resolutions.

**Agent 3 - User Preferences & Blockers**: Find user instructions about workflow, communication style, or explicit requests. Find unresolved blockers or TODO items.

## Step 5: Create Handover Document

Write `~/.claude/handover/resume-prompt.md` with exactly these sections:

```markdown
# Handover: [Brief Task Description]
Generated: [timestamp]
Session: [session_id]

## DO FIRST
[The single most important next action. Be specific: exact file, exact change, exact command.]

## DO NOT TOUCH
[Working/fragile things to leave alone. List specific files or systems that are stable and should not be modified.]

## Key Decisions
[Each decision with its rationale. Format: "We chose X over Y because Z."]

## Modified Files
[Each file with 1-line context of what was changed and why.]

## Active Blockers
[Unresolved issues, failing tests, missing dependencies, pending user input.]

## User Preferences
[Workflow style, communication preferences, explicit instructions given during the session.]

## Task Progress
[What's done, what's in progress, what's remaining. Use checkboxes.]
- [x] Completed items
- [ ] Remaining items
```

Be **prescriptive**: "Change line 42 of foo.ts to use async/await" not "We were working on foo.ts".
Be **specific**: Include exact file paths, line numbers where possible, and concrete next steps.
Be **honest**: If you couldn't determine something from the transcript, say so.
