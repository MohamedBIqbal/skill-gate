---
name: persisting-context
description: Context persistence across Claude Code sessions — save/load patterns, compression, session handoff. For mid-task saves and cross-session continuity.
user-invocable: false
---

# Context Persistence Skill

A skill for preserving conversation context across Claude Code sessions.

## Core Principle

**"Save context before you lose it; load context before you need it."**

This skill enables explicit context management - complementing (not replacing) Claude's built-in auto-memory with inspectable, version-controlled persistence.

| Concern | Built-in Memory | This Skill |
|---------|-----------------|------------|
| Visibility | Opaque | Explicit files |
| Control | Automatic | Manual trigger |
| Versioning | None | Git-tracked |
| Searchability | Limited | Topic tags, file index |

---

## When to Use

### Save Context When:
- Approaching context window limits (~20% remaining)
- Making important architectural decisions
- Completing a major feature/milestone
- Switching topics significantly
- User explicitly requests "save context" or "remember this"
- Session ending with work in progress

### Load Context When:
- Starting a new session on existing project
- User mentions "where were we" or "continuing from..."
- Topic matches existing context file tags
- Referencing files that appear in previous context

---

## Quick Reference

### Save Context
1. Create file: `.claude/context/active/session-YYYY-MM-DD-topic.md`
2. Use template below
3. **Save active plans**: Copy any `.claude/plans/*.md` into the context file's `## Active Plans` section (plans are ephemeral and wiped between sessions)
4. Update `.claude/context/_index.md`

### Load Context
1. Read `.claude/context/_index.md`
2. Match by topic tags or file references
3. Read matched context file(s)
4. Follow continuation instructions

---

## Directory Structure

```
.claude/
├── context/
│   ├── _index.md              # Registry of all context files
│   ├── active/                # Recent context (0-7 days)
│   │   └── session-YYYY-MM-DD-topic.md
│   └── archive/               # Older context (7-30 days)
│       └── session-YYYY-MM-DD-topic.md
├── plans/                     # Ephemeral — Claude Code wipes between sessions
│   └── *.md                   # Active plans (auto-generated names)
└── skills/                    # Project skills
    └── */SKILL.md
```

---

## Context File Template

Use this structure when saving context:

```markdown
---
session_id: session-YYYY-MM-DD-topic
created: YYYY-MM-DDTHH:MM:SS
topic_tags: [tag1, tag2, tag3]
files_modified: [file1.py, file2.tsx]
continuation_priority: high|medium|low
---

# Session Context: [Descriptive Title]

## Summary
[1-2 paragraphs: What was accomplished, what's the current state, what's next]

## Key Decisions Made

| # | Decision | Rationale | Files Affected |
|---|----------|-----------|----------------|
| 1 | [What was decided] | [Why this choice] | [file1.py, file2.py] |

## Current State

### Completed
- [x] Item that was finished

### In Progress
- [ ] Item being worked on

### Blocked / Needs Attention
- Issue that needs resolution

## Active Plans

[Copy contents of any `.claude/plans/*.md` files here. Plans are ephemeral —
Claude Code deletes them between sessions. Without this section, plan context
is lost on session restart.]

### Plan: [plan-name-from-filename]
[Full plan content — steps, checkboxes, status, notes]

## Files to Review First

When resuming, read these files in order:
1. `/path/to/primary/file.py` - Core logic
2. `/path/to/related/file.tsx` - UI component

## Continuation Instructions

When resuming this work:
1. [First thing to do or check]
2. [Second priority action]
3. [Any skill files to reference]
```

---

## Index File Format

The index at `.claude/context/_index.md` follows this structure:

```markdown
# Context Index

Last updated: YYYY-MM-DDTHH:MM:SS

## Active Context Files

| File | Topic Tags | Priority | Created | Summary |
|------|------------|----------|---------|---------|
| `active/session-YYYY-MM-DD-topic.md` | tag1, tag2 | high | YYYY-MM-DD | Brief summary |

## Archived Context Files

| File | Topic Tags | Created | Summary |
|------|------------|---------|---------|
| `archive/session-YYYY-MM-DD-topic.md` | tag1 | YYYY-MM-DD | Brief summary |

## Quick Search

### By Topic
- **tag1**: session-file1.md, session-file2.md

### By File Modified
- `file.py`: session-file1.md
```

---

## Size Management

### Limits

| Constraint | Limit | Action When Exceeded |
|------------|-------|----------------------|
| Single context file | 500 lines / 20KB | Split into multiple files |
| Total active context | 5 files | Archive oldest low-priority |
| Index entries | 50 active | Archive entries >30 days |

### Split Strategy

When a session exceeds 500 lines:

**Option 1 - Split by topic (preferred):**
- `session-YYYY-MM-DD-topic-backend.md`
- `session-YYYY-MM-DD-topic-frontend.md`

**Option 2 - Split chronologically:**
- `session-YYYY-MM-DD-topic-part1.md`
- `session-YYYY-MM-DD-topic-part2.md`

Link related files in "Related Context Files" section.

### Content Priority (What to Keep vs Trim)

| Priority | Content | Action |
|----------|---------|--------|
| Critical | Key decisions table | Always keep |
| Critical | Active plans (`.claude/plans/`) | Always keep — ephemeral, lost on session end |
| Critical | Continuation instructions | Always keep |
| Critical | Files to review | Always keep |
| High | In-progress items | Keep if actionable |
| Medium | Code patterns | Keep if unique/non-obvious |
| Low | Completed items | Summarize, trim details |

---

## Archival Policy

| Age | Location | Action |
|-----|----------|--------|
| 0-7 days | `active/` | Keep |
| 7-30 days | `archive/` | Move, keep in index |
| >30 days | Delete | Unless `priority: high` |

### Archival Checklist

Before archiving:
1. Check for unresolved in-progress items
2. If unresolved: keep in active OR create new file with just those items
3. Update `_index.md` to reflect new location
4. Update Quick Search sections

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| **Context Dumping** | Saving everything makes files unreadable | Focus on decisions, patterns, next steps |
| **Missing Continuation** | Next session starts from scratch | Always include continuation instructions |
| **No Topic Tags** | Hard to find relevant context later | Tag with all relevant topics |
| **Stale Context** | Outdated info misleads future sessions | Follow archival policy, check dates |
| **Monolithic File** | Exceeds size limits, slow to load | Split at 500 lines by topic |

---

## Trigger Detection

### Signs Context is Running Low
- Claude mentions summarizing or losing detail
- Responses become less specific about earlier discussion
- User notices repetition or forgotten context
- Long-running session (many tool calls)

### Proactive Save Triggers
- Before starting a new major topic
- After completing a significant milestone
- Before switching to a different feature/area
- When user will be away (end of day, meeting)

---

## Integration Commands

### /save-context
When user says "save context" or similar:
1. Gather key decisions from conversation
2. Identify files modified
3. Note current state and next steps
4. **Capture active plans**: Read all `.claude/plans/*.md` files and embed their full content into the context file's `## Active Plans` section (plans are ephemeral — Claude Code wipes them between sessions)
5. Create context file using template
6. Update index

### /load-context [topic]
When user wants to resume previous work:
1. Read index file
2. Find matches by topic tag
3. Load most relevant context file
4. Summarize continuation instructions to user

### /cleanup-context
Periodic maintenance:
1. List all context files with age and priority
2. Recommend archival/deletion candidates
3. Confirm with user before acting
4. Update index

---

## Composition Checklist

### When Saving Context:
- [ ] Summary captures current state accurately
- [ ] Key decisions have rationale (not just what, but why)
- [ ] **Active plans captured** from `.claude/plans/*.md` (they won't survive session end)
- [ ] Topic tags cover all relevant areas
- [ ] Files to review are in priority order
- [ ] Continuation instructions are actionable
- [ ] Under 500 lines

### When Loading Context:
- [ ] Checked index for matching topics
- [ ] Read most recent/relevant file
- [ ] Verified context still applicable (check dates)
- [ ] Summarized continuation to user
