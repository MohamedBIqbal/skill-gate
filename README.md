# Skill-Gate

**Make Claude Code check your project skills before using built-in knowledge.**

Claude Code skills are powerful but advisory — Claude decides whether to use them. Skill-Gate adds a two-layer enforcement system that ensures your project expertise is consulted first.

## The Problem

You've built project-specific skills encoding your architecture decisions, quality standards, and domain patterns. But Claude Code's skill triggering is based on description matching — Claude reads descriptions, decides if they're relevant, and may skip them entirely. There's no built-in "skills first" mechanism.

## The Solution

Skill-Gate uses two layers:

| Layer | Mechanism | Reliability |
|-------|-----------|-------------|
| **Hook** (active) | `UserPromptSubmit` hook injects a reminder into Claude's context on every non-trivial prompt | High — fires before Claude starts thinking |
| **Skill** (passive) | `skill-first` router skill auto-discovers all project skills and instructs Claude to check them | Medium — triggered by description matching |

Together, they provide defense in depth. Even if the skill description matching fails, the hook catches it.

## Install

```bash
# Clone the repo
git clone https://github.com/MohamedBIqbal/skill-gate.git

# Install into your project
bash skill-gate/install.sh /path/to/your/project

# Restart Claude Code or visit /hooks
```

### What gets installed

```
your-project/
└── .claude/
    ├── settings.json              # Hook wiring (merged with existing)
    ├── hooks/
    │   └── skill-first-check.sh   # Auto-discovers skills, injects reminder
    ├── skills/
    │   ├── skill-first/SKILL.md   # Router skill — finds matching skills
    │   └── context/SKILL.md       # Session persistence across restarts
    └── context/
        ├── _index.md              # Context file registry
        ├── active/                # Recent session context
        └── archive/               # Older session context
```

### Manual Install

If you prefer to install manually:

1. Copy `skills/skill-first/` and `skills/context/` into your `.claude/skills/`
2. Copy `hooks/skill-first-check.sh` into `.claude/hooks/` and `chmod +x` it
3. Add the hook to your `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/skill-first-check.sh",
            "timeout": 5,
            "statusMessage": "Checking project skills..."
          }
        ]
      }
    ]
  }
}
```

## How It Works

### The Hook (Layer 1)

On every prompt submission, `skill-first-check.sh`:

1. Checks if the prompt is trivial (git commands, greetings, short confirmations) — if so, skips
2. Auto-discovers all skills by scanning `.claude/skills/*/SKILL.md`
3. Injects a `SKILL-GATE` reminder into Claude's context listing all available skills
4. Claude receives this before it starts reasoning about your prompt

**Smart filtering** — the hook stays silent for:
- Git commands (`git status`, `git log`, etc.)
- Simple confirmations (`yes`, `no`, `ok`, `sure`)
- Greetings (`hello`, `hi`, `hey`)
- Short prompts (fewer than 4 words)
- CLI commands (`/clear`, `/help`, `/compact`)

### The Skill (Layer 2)

The `skill-first` skill acts as a router:

1. Claude's description matching picks it up for implementation/design/planning tasks
2. It instructs Claude to scan all skills, classify the task by domain, and invoke matching skills
3. It emphasizes multi-skill tasks (most real work touches 2-4 domains)

### Context Persistence (Bonus)

The `context` skill preserves session state across Claude Code restarts:

- **Save**: Creates structured context files with decisions, state, and continuation instructions
- **Load**: Reads the index, finds matching context by topic tags
- **Archive**: Manages lifecycle (active → archive → delete)

Say `save context` before ending a session. Say `load context` or `where were we` to resume.

## Uninstall

```bash
bash /path/to/skill-gate/uninstall.sh /path/to/your/project
```

Removes skills, hook, and cleans `settings.json`. Context files are preserved.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (for JSON parsing in the hook)
- Bash 4+

## How It Compares

| Approach | Mechanism | Reliability | Maintenance |
|----------|-----------|-------------|-------------|
| Better skill descriptions | Match keywords in description | Medium | Per-skill |
| CLAUDE.md instructions | Advisory text | Low-Medium | Manual |
| Manual `/skill-name` | User invokes directly | High | User remembers |
| **Skill-Gate** | Hook + Skill (two layers) | **High** | **Auto-discovers** |

## Limitations

- Neither layer can truly *force* Claude to use skills — both inject context that Claude *should* follow but technically can ignore
- The hook adds a subprocess spawn per prompt (< 50ms)
- First-time setup may require a session restart for the settings watcher to pick up new files
- `jq` must be installed (most systems have it; `brew install jq` on macOS)

## License

MIT
