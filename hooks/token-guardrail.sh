#!/bin/bash
# Token efficiency guardrail — injects cost-awareness into Claude's context
# when it's about to spawn agents or load multiple skills.
#
# Hook type: UserPromptSubmit (context injection, non-blocking)
# Fires on every prompt. Adds a brief reminder about token-efficient patterns.
# Cost: ~200 tokens per turn — pays for itself by preventing 10K+ token waste.
# https://github.com/MohamedBIqbal/skill-gate

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# Skip trivial prompts (< 5 words)
WORD_COUNT=$(echo "$PROMPT" | wc -w | tr -d ' ')
if [ "$WORD_COUNT" -lt 5 ]; then
  exit 0
fi

# Detect high-cost patterns in the prompt
WARNINGS=""

# Pattern 1: Many skill names mentioned (likely loading several)
# Users should customize this list with their project's skill names
SKILL_COUNT=$(echo "$PROMPT" | grep -oiE '(/[a-z-]+){4,}' | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -gt 0 ]; then
  WARNINGS="${WARNINGS}TOKEN-WARN: Multiple skills referenced. The skill-queue hook should handle phased loading via subagents. If loading skills manually, use Agent tool delegation instead of Skill tool to avoid permanent context cost. "
fi

# Pattern 2: Parallel agents mentioned
if echo "$PROMPT" | grep -qiE '(parallel|concurrent|simultaneous).*(agent|subagent)'; then
  WARNINGS="${WARNINGS}TOKEN-WARN: Parallel agents multiply token cost linearly. Use model:haiku or model:sonnet for subagents doing research/exploration — reserve Opus for complex reasoning. "
fi

# Pattern 3: Broad exploration requested
if echo "$PROMPT" | grep -qiE '(review.*(entire|all|whole|full)|improve.*(codebase|everything)|explore.*(all|entire))'; then
  WARNINGS="${WARNINGS}TOKEN-WARN: Broad exploration is token-expensive. Scope to specific files or directories. Use Explore subagent (haiku) to isolate verbose output from main context. "
fi

# Only inject if warnings were generated
if [ -n "$WARNINGS" ]; then
  # Escape for JSON
  WARNINGS_JSON=$(echo "$WARNINGS" | jq -Rs '.')
  echo "{
    \"hookSpecificOutput\": {
      \"hookEventName\": \"UserPromptSubmit\",
      \"additionalContext\": ${WARNINGS_JSON}
    }
  }"
fi

exit 0
