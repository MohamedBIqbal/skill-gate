# Skill-Gate

**Make Claude Code check your project skills before using built-in knowledge.**

Claude Code skills are powerful but advisory — Claude decides whether to use them. Skill-Gate adds enforcement hooks that ensure your project expertise is consulted first, and a **skill queue** that loads multi-skill tasks one at a time via subagents to save context tokens.

## Why Skill-Gate

| Scenario | Without Skill-Gate | With Skill-Gate |
|----------|-------------------|-----------------|
| **Single-skill task** | Claude may skip your skill entirely | Hook injects `SKILL-MATCH` — Claude loads the skill |
| **Multi-skill task** (e.g. 4 skills) | All 4 skill bodies load into main context (~20K tokens, permanent) | Queue protocol: each skill runs in an isolated subagent (~800 tokens in main context) |
| **After context compaction** | Skill bodies lost, Claude forgets they exist | PostCompact hook re-injects skill awareness |
| **New skills added** | Must restart session for discovery | Auto-detected via filesystem scan + index rebuild |

### Cost-Benefit (4-skill task example)

| Metric | Before (all loaded) | After (queued) | Savings |
|--------|-------------------|----------------|---------|
| Main context consumed | ~20K tokens (4 × 5K) | ~800 tokens (queue text only) | **~19K tokens** |
| Tokens carried per turn | 20K × remaining turns | 800 × remaining turns | **Compounds over session** |
| Attention dilution | 4 full skill bodies competing | Only summaries, focused | **Better output quality** |
| Subagent overhead | N/A | ~2K tokens per skill | Paid once per skill |

**Break-even**: Any multi-skill task saves more context than the subagent overhead costs. A 4-skill task saves ~12K tokens net, compounding every turn.

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
    ├── settings.json                    # Hook wiring (merged with existing)
    ├── hooks/
    │   ├── skill-queue.sh              # Smart matching + queue protocol
    │   ├── build-skill-index.sh        # Generates keyword index from skill descriptions
    │   ├── token-guardrail.sh          # Warns about high-cost patterns
    │   ├── post-compact-remind.sh      # Re-injects skill awareness after compaction
    │   ├── skill-phases.conf.example   # Phase ordering template (customize this)
    │   └── skill-first-check.sh        # Legacy hook (flat list, no queue)
    ├── skills/
    │   ├── skill-first/SKILL.md        # Router skill with queue protocol
    │   └── context/SKILL.md            # Session persistence across restarts
    └── context/
        ├── _index.md                   # Context file registry
        ├── active/                     # Recent session context
        └── archive/                    # Older session context
```

### Manual Install

If you prefer to install manually:

1. Copy `skills/skill-first/` and `skills/context/` into your `.claude/skills/`
2. Copy all files from `hooks/` into `.claude/hooks/` and `chmod +x` the `.sh` files
3. Add the hooks to your `.claude/settings.json` (see `examples/settings.json`)

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│ Claude Code Session                                              │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Hook Layer (fires before Claude thinks)                     │ │
│  │                                                             │ │
│  │  UserPromptSubmit ──┬── skill-queue.sh ── skill-index.txt   │ │
│  │                     └── token-guardrail.sh                  │ │
│  │                                                             │ │
│  │  PostCompact ────────── post-compact-remind.sh              │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                          │                                       │
│                    injects context                                │
│                          ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Skill Layer (Claude reads when triggered)                   │ │
│  │                                                             │ │
│  │  skill-first/SKILL.md ── routing protocol + queue protocol  │ │
│  │  context/SKILL.md ────── session persistence                │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                          │                                       │
│              0 match: flat list reminder                          │
│              1 match: "use Skill tool"                            │
│              2+ match: queue protocol ──────────┐                │
│                                                  ▼               │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │ Subagent Execution (isolated context per skill)           │   │
│  │                                                           │   │
│  │  Phase 1 ─► subagent reads spec skill ─► returns summary  │   │
│  │  Phase 2 ─► subagent reads domain skill ─► returns summary│   │
│  │  Phase 3 ─► subagent reads quality skill ─► returns summary│  │
│  │                                                           │   │
│  │  Main context only holds: queue + summaries (~800 tokens)  │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Index Layer (auto-maintained)                               │ │
│  │                                                             │ │
│  │  build-skill-index.sh ── reads SKILL.md frontmatter         │ │
│  │           │               descriptions, extracts keywords   │ │
│  │           ▼                                                 │ │
│  │  skill-index.txt ──────── skill-name:keyword1,keyword2,...  │ │
│  │  skill-phases.conf ────── skill-name:phase:label (optional) │ │
│  │                                                             │ │
│  │  Auto-rebuilds when: new skills added, SKILL.md modified    │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## Usage

### New Project

```bash
# 1. Clone skill-gate
git clone https://github.com/MohamedBIqbal/skill-gate.git

# 2. Install (creates .claude/ structure from scratch)
bash skill-gate/install.sh /path/to/new/project

# 3. Add your own skills
mkdir -p /path/to/new/project/.claude/skills/my-skill
cat > /path/to/new/project/.claude/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does — include trigger keywords for matching.
---
# My Skill
Instructions here...
EOF

# 4. Index auto-rebuilds on next prompt, or rebuild manually:
/path/to/new/project/.claude/hooks/build-skill-index.sh

# 5. (Optional) Customize phase ordering
cp .claude/hooks/skill-phases.conf.example .claude/hooks/skill-phases.conf
# Edit skill-phases.conf with your skill-to-phase mappings
```

### Existing Project (has .claude/settings.json and skills)

```bash
# 1. Install — merges hooks into existing settings.json
bash skill-gate/install.sh /path/to/existing/project

# If settings.json already has UserPromptSubmit hooks, you'll see a warning.
# Manually merge from examples/settings.json in that case.

# 2. The index auto-builds from your existing skills' SKILL.md descriptions.
#    Verify it found your skills:
cat /path/to/existing/project/.claude/hooks/skill-index.txt

# 3. (Optional) Customize phase ordering for your skill set
cp .claude/hooks/skill-phases.conf.example .claude/hooks/skill-phases.conf
# Map your skills to phases:
#   my-spec-skill:1:spec
#   my-domain-skill:3:domain
#   my-testing-skill:5:quality
```

### Migrating from Skill-Gate v1

```bash
# Option A: Re-run installer (adds new files alongside v1)
bash skill-gate/install.sh /path/to/project
# Then update settings.json: replace skill-first-check.sh with skill-queue.sh

# Option B: Clean reinstall
bash skill-gate/uninstall.sh /path/to/project
bash skill-gate/install.sh /path/to/project
```

## How It Works

```
User prompt arrives
        │
   skill-queue.sh (hook)
        │
   Match prompt keywords against skill-index.txt
        │
   ┌────┼────────────────┐
   │    │                 │
0 match  1 match       2+ matches
   │    │                 │
SKILL-GATE  SKILL-MATCH   SKILL-QUEUE
(flat list)  (use Skill   (phased subagent
             tool)         delegation)
```

### The Skill Queue (2+ matches)

When multiple skills match, the hook injects a **SKILL-QUEUE** protocol:

1. Skills are assigned to phases: `spec → design → domain → implement → quality → ops`
2. Claude executes each phase by spawning a **subagent** via the Agent tool
3. Each subagent reads the skill's `SKILL.md`, applies it to the task, returns a summary
4. Summaries chain forward — each phase gets context from prior phases
5. Skill bodies stay in subagent context only, **never loading into main context**

This means a task matching `vision + privacy + tdd + ai-code-review` costs ~800 tokens in main context instead of ~20K.

### Phase Ordering

Customize skill-to-phase mapping by copying `hooks/skill-phases.conf.example` to `hooks/skill-phases.conf`:

```
# Format: skill-name:phase-number:phase-label
spec-driven-dev:1:spec
vision:3:domain
privacy:3:domain
tdd:5:quality
ai-code-review:5:quality
observability:6:ops
```

Skills not listed default to phase 3 (implement).

### Auto-Rebuilding Index

The skill index (`skill-index.txt`) is built from SKILL.md frontmatter descriptions. It auto-rebuilds when:
- A new skill is added (file count mismatch)
- A skill's SKILL.md is modified (mtime check)
- You run `build-skill-index.sh` manually

### Smart Filtering

The hook stays silent for:
- Git commands (`git status`, `git log`, etc.)
- Simple confirmations (`yes`, `no`, `ok`, `sure`, `yep`, `nope`)
- Greetings (`hello`, `hi`, `hey`)
- Short prompts (fewer than 4 words)
- CLI commands (`/clear`, `/help`, `/compact`, `/commit`)

### Token Guardrail

A separate `token-guardrail.sh` hook warns about high-cost patterns:
- Multiple skills referenced explicitly (suggests queue protocol)
- Parallel agent requests (suggests cheaper models for subagents)
- Broad exploration requests (suggests scoping)

### PostCompact Recovery

When Claude Code compresses conversation history, skill bodies and queue state are lost. The `post-compact-remind.sh` hook fires after compaction and reminds Claude to resume any in-progress queue or re-invoke active skills.

## How It Compares

| Approach | Matching | Multi-skill cost | Maintenance |
|----------|----------|-----------------|-------------|
| Better skill descriptions | Keyword-based | All loaded (~5K × N tokens) | Per-skill |
| CLAUDE.md instructions | Advisory | Manual loading | Manual |
| Manual `/skill-name` | User invokes | User decides | User remembers |
| **Skill-Gate v1** | None (flat list) | All loaded (~5K × N tokens) | Auto-discovers |
| **Skill-Gate v2** | **Keyword index** | **~800 tokens (subagent queue)** | **Auto-discovers + auto-rebuilds** |

## Upgrading from v1

If you have skill-gate v1 installed:

1. Re-run `install.sh` — it will add the new hooks alongside the existing ones
2. Update your `settings.json` to use `skill-queue.sh` instead of `skill-first-check.sh` (see `examples/settings.json`)
3. The legacy `skill-first-check.sh` is kept as a fallback

Or uninstall and reinstall:
```bash
bash /path/to/skill-gate/uninstall.sh /path/to/your/project
bash /path/to/skill-gate/install.sh /path/to/your/project
```

## Limitations

- Neither layer can truly *force* Claude to use skills — both inject context that Claude *should* follow but technically can ignore
- Keyword matching requires 2+ keyword overlap (may miss skills with unique single-word triggers)
- The hook adds ~1.5s per prompt (keyword matching against index)
- Phase ordering is generic by default — customize `skill-phases.conf` for best results
- `jq` must be installed (most systems have it; `brew install jq` on macOS)

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` — `brew install jq` (macOS) / `apt install jq` (Linux)
- Bash 3.2+ and standard POSIX tools (`find`, `grep`, `awk`, `sort`, `tr`, `sed`)
- Works on **macOS**, **Linux**, and **Windows (WSL)**. No OS-specific dependencies.

## License

MIT
