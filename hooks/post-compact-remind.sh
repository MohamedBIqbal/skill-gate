#!/bin/bash
# Post-Compact Hook — Re-injects skill awareness after context compaction
# Skill bodies are lost during compaction; this reminds Claude they exist
# https://github.com/MohamedBIqbal/skill-gate

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SKILLS_DIR="${PROJECT_DIR}/.claude/skills"

if [ ! -d "$SKILLS_DIR" ]; then exit 0; fi

SKILL_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -eq 0 ]; then exit 0; fi

cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "PostCompact",
    "additionalContext": "Context was compacted. Skill bodies may have been lost. If you were actively using a skill, re-invoke it with /skill-name. Project has ${SKILL_COUNT} skills available."
  }
}
ENDJSON
