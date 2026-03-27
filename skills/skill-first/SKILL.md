---
name: skill-first
description: Skill router — scans tasks against project skills, recommends invocations before implementation. Pre-flight checklist for design, review, planning. Triggers on non-trivial tasks.
user-invocable: false
---

# Skill-First Router

Before using built-in knowledge to solve or design anything, check this project's skills catalog. Project skills encode hard-won domain decisions, architectural patterns, and quality standards specific to this codebase.

## Routing Protocol

When a task arrives, the `skill-queue.sh` hook auto-matches skills and injects one of:

- **SKILL-MATCH** (1 skill): Use the `Skill` tool to load it directly — low overhead.
- **SKILL-QUEUE** (2+ skills): Follow the queue protocol below — do NOT load all via Skill tool.
- **SKILL-GATE** (0 matches): Check the catalog manually, the hook couldn't auto-match.

### Skill Queue Protocol (2+ skills)

When the hook injects a SKILL-QUEUE with phased skills:

1. **For each skill in phase order**, spawn a subagent via the `Agent` tool (model: sonnet).
2. **Subagent prompt template**: "Read `.claude/skills/{name}/SKILL.md`. Apply its guidance to this task: {task description}. Return a structured summary: key decisions, constraints, artifacts to create."
3. **Chain context**: Pass accumulated phase summaries to each subsequent subagent.
4. **Synthesize**: After all phases, combine summaries into your response.
5. **Never load queued skills via Skill tool** — that permanently consumes main context tokens.
6. **Single follow-up**: If a later question only involves one skill, the Skill tool is fine.

## Auto-Discovery

Read `.claude/skills/*/SKILL.md` to discover available skills. Each skill's YAML frontmatter contains:
- `name` — Skill identifier
- `description` — What it does and when to use it

Match the task against each skill's description. Look for keyword overlap, domain match, and contextual relevance.

## Multi-Skill Tasks

Most real tasks touch multiple domains. The hook auto-matches and queues them. Examples:
- "Add an API endpoint" → security skill + testing skill + domain-specific skill
- "Build the dashboard" → UI skill + observability skill + data skill
- "Deploy the service" → infrastructure skill + security skill + monitoring skill

The hook assigns matched skills to phases: spec → design → domain → implement → quality → ops.

## When NOT to Route

Skip routing for:
- Simple file reads, git operations, or quick lookups
- Conversational questions that don't involve implementation
- Tasks the user explicitly says to handle without skills
- Prompts shorter than a sentence
