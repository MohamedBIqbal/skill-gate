#!/bin/bash
# Skill-Gate Hook — Auto-discovers project skills and reminds Claude to check them first
# Fires on every UserPromptSubmit, injects context reminder
# https://github.com/YOUR_USERNAME/skill-gate

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Skip reminders for simple operations
if echo "$PROMPT" | grep -qiE '^(git |ls |cat |/clear|/help|/compact|/hooks|hey|hi |hello|thanks|thank you|yes|no|ok|sure|go ahead)'; then
  exit 0
fi

# Skip for very short prompts (likely conversational)
WORD_COUNT=$(echo "$PROMPT" | wc -w | tr -d ' ')
if [ "$WORD_COUNT" -lt 4 ]; then
  exit 0
fi

# Auto-discover skills from .claude/skills/
SKILLS_DIR=".claude/skills"
if [ -d "$SKILLS_DIR" ]; then
  SKILL_LIST=$(find "$SKILLS_DIR" -name "SKILL.md" -maxdepth 2 | while read -r f; do
    dir=$(dirname "$f")
    basename "$dir"
  done | grep -v "skill-first" | sort | tr '\n' ', ' | sed 's/,$//')
  SKILL_COUNT=$(echo "$SKILL_LIST" | tr ',' '\n' | wc -w | tr -d ' ')
else
  SKILL_LIST=""
  SKILL_COUNT=0
fi

# If no skills found, skip
if [ "$SKILL_COUNT" -eq 0 ]; then
  exit 0
fi

cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "SKILL-GATE: This project has ${SKILL_COUNT} skills. Before implementing or designing anything, check if any match this task: ${SKILL_LIST}. Invoke matching skills BEFORE using built-in knowledge."
  }
}
ENDJSON
exit 0
