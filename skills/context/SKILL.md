---
name: persisting-context
description: Preserves conversation context across Claude Code sessions — save and load patterns, context compression, session handoff strategies. Use when starting a new session that needs prior context, saving progress mid-task, or designing context persistence for agent workflows.
user-invocable: false
---

# Context Persistence Skill

Preserve conversation context across Claude Code sessions with inspectable, version-controlled files.

## Core Principle

**"Save context before you lose it; load context before you need it."**

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
| 1 | [What was decided] | [Why this choice] | [file1.py] |

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

## Files to Review First

When resuming, read these files in order:
1. `/path/to/primary/file.py` - Core logic

## Continuation Instructions

When resuming this work:
1. [First thing to do or check]
2. [Second priority action]
```

---

## Index File Format

Maintain at `.claude/context/_index.md`:

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

| Constraint | Limit | Action When Exceeded |
|------------|-------|----------------------|
| Single context file | 500 lines / 20KB | Split into multiple files |
| Total active context | 5 files | Archive oldest low-priority |
| Index entries | 50 active | Archive entries >30 days |

### Content Priority

| Priority | Content | Action |
|----------|---------|--------|
| Critical | Key decisions, active plans, continuation instructions, files to review | Always keep |
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

---

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Context Dumping | Unreadable files | Focus on decisions, next steps |
| Missing Continuation | Cold start next session | Always include continuation instructions |
| No Topic Tags | Can't find context later | Tag with all relevant topics |
| Stale Context | Misleads future sessions | Follow archival policy |
| Monolithic File | Exceeds limits | Split at 500 lines by topic |

---

## Integration Commands

### /save-context
1. Gather key decisions from conversation
2. Identify files modified
3. Note current state and next steps
4. Capture active plans from `.claude/plans/*.md`
5. Create context file using template
6. Update index

### /load-context [topic]
1. Read `.claude/context/_index.md`
2. Find matches by topic tag
3. Load most relevant context file
4. Summarize continuation instructions to user

### /cleanup-context
1. List all context files with age and priority
2. Recommend archival/deletion candidates
3. Confirm with user before acting
4. Update index
