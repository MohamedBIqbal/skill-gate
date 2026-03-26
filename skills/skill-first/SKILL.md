---
name: skill-first
description: Skill router — scans tasks against project skills, recommends invocations before implementation. Pre-flight checklist for design, review, planning. Triggers on non-trivial tasks.
user-invocable: false
---

# Skill-First Router

Before using built-in knowledge to solve or design anything, check this project's skills catalog. Project skills encode hard-won domain decisions, architectural patterns, and quality standards specific to this codebase.

## Routing Protocol

When a task arrives:

1. **Classify the task** — What domains does it touch? (vision, security, testing, UI, infrastructure, AI/ML, documentation, etc.)
2. **Match against skills** — Find all skills in `.claude/skills/` whose domain overlaps with the task. Read each `SKILL.md` description to determine relevance.
3. **Invoke matched skills** — Load them via the Skill tool before writing any code or making design decisions
4. **Proceed with skill context** — Only after skill knowledge is loaded, begin implementation

## Auto-Discovery

Read `.claude/skills/*/SKILL.md` to discover available skills. Each skill's YAML frontmatter contains:
- `name` — Skill identifier
- `description` — What it does and when to use it

Match the task against each skill's description. Look for keyword overlap, domain match, and contextual relevance.

## Multi-Skill Tasks

Most real tasks touch multiple domains. Examples:
- "Add an API endpoint" → security skill + testing skill + domain-specific skill
- "Build the dashboard" → UI skill + observability skill + data skill
- "Deploy the service" → infrastructure skill + security skill + monitoring skill

Always identify ALL relevant skills, not just the primary one.

## When NOT to Route

Skip routing for:
- Simple file reads, git operations, or quick lookups
- Conversational questions that don't involve implementation
- Tasks the user explicitly says to handle without skills
- Prompts shorter than a sentence
