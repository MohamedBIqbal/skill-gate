#!/bin/bash
# Build Skill Index — Generates skill-index.txt from SKILL.md frontmatter descriptions
# Run manually after adding or modifying skills, or let skill-queue.sh auto-rebuild.
#
# Output: .claude/hooks/skill-index.txt
# Format: skill-name:keyword1,keyword2,keyword3,...
# https://github.com/MohamedBIqbal/skill-gate

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="${PROJECT_DIR}/.claude/skills"
OUTPUT="${SCRIPT_DIR}/skill-index.txt"

# Stop words to filter out (common English words that don't help matching)
STOP_WORDS="a|an|the|and|or|for|to|of|in|on|at|by|with|from|as|is|it|its|this|that|use|when|how|be|are|was|were|been|being|have|has|had|do|does|did|will|would|could|should|can|may|might|shall|not|no|but|if|than|then|so|very|just|also|into|over|such|only|about|up|out|all|each|every|both|few|more|most|other|some|any|many|much|own|same|new|old|first|last|long|great|little|right|good|well|way|back|even|still|too|here|there|where|after|before|between|under|during"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "Error: Skills directory not found at $SKILLS_DIR" >&2
  exit 1
fi

> "$OUTPUT"  # Truncate output file

find "$SKILLS_DIR" -name "SKILL.md" -maxdepth 2 | sort | while read -r skill_file; do
  skill_name=$(basename "$(dirname "$skill_file")")

  # Skip the skill-first router itself
  if [ "$skill_name" = "skill-first" ]; then
    continue
  fi

  # Extract description from YAML frontmatter
  # Frontmatter is between first --- and second ---
  description=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$skill_file" \
    | grep -i '^description:' \
    | sed 's/^description:[[:space:]]*//' \
    | tr '[:upper:]' '[:lower:]')

  if [ -z "$description" ]; then
    continue
  fi

  # Tokenize: strip punctuation, split on spaces/special chars, filter stop words
  keywords=$(echo "$description" \
    | tr -cs '[:alpha:]' '\n' \
    | grep -v '^$' \
    | grep -vwE "^(${STOP_WORDS})$" \
    | sort -u \
    | tr '\n' ',' \
    | sed 's/,$//')

  if [ -n "$keywords" ]; then
    echo "${skill_name}:${keywords}" >> "$OUTPUT"
  fi
done

count=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "Built skill index: ${count} skills → ${OUTPUT}"
