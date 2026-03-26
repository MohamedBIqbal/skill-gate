---
name: skill-first
description: Routes tasks to project skills before using built-in knowledge. Auto-discovers all skills in .claude/skills/ and recommends which to invoke. Use when starting any implementation, design, review, or planning task — acts as a pre-flight checklist ensuring project expertise is applied first. TRIGGER when beginning work on any non-trivial task. DO NOT TRIGGER for simple questions, git commands, or file reads.
user-invocable: false
---

# Skill-First Router

Before using built-in knowledge to solve or design anything, check this project's skills. Project skills encode domain decisions, architectural patterns, and quality standards specific to this codebase.

## Routing Protocol

When a task arrives:

1. **Scan available skills** — List all directories in `.claude/skills/`, read each `SKILL.md` description
2. **Classify the task** — What domains does it touch?
3. **Match against skills** — Find all skills whose description overlaps with the task
4. **Invoke matched skills** — Load them via the Skill tool before writing any code or making design decisions
5. **Proceed with skill context** — Only after skill knowledge is loaded, begin implementation

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
