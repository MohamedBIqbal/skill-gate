#!/bin/bash
# Skill-Gate Uninstaller
# Removes skills, hooks, and cleans settings.json
set -e

TARGET_DIR="${1:-.}"

echo "Skill-Gate Uninstaller"
echo "======================"
echo "Target: $(cd "$TARGET_DIR" && pwd)"
echo ""

# Confirm
read -p "This will remove skill-gate files. Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Remove skills
if [ -d "$TARGET_DIR/.claude/skills/skill-first" ]; then
  rm -rf "$TARGET_DIR/.claude/skills/skill-first"
  echo "Removed: skills/skill-first"
fi

if [ -d "$TARGET_DIR/.claude/skills/context" ]; then
  read -p "Remove context skill? This won't delete saved context files. [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$TARGET_DIR/.claude/skills/context"
    echo "Removed: skills/context"
  else
    echo "Kept: skills/context"
  fi
fi

# Remove hooks
for hook in skill-queue.sh skill-first-check.sh build-skill-index.sh token-guardrail.sh post-compact-remind.sh; do
  if [ -f "$TARGET_DIR/.claude/hooks/$hook" ]; then
    rm "$TARGET_DIR/.claude/hooks/$hook"
    echo "Removed: hooks/$hook"
  fi
done

# Remove generated files
for f in skill-index.txt skill-phases.conf skill-phases.conf.example; do
  if [ -f "$TARGET_DIR/.claude/hooks/$f" ]; then
    rm "$TARGET_DIR/.claude/hooks/$f"
    echo "Removed: hooks/$f"
  fi
done

# Clean hooks from settings.json
SETTINGS_FILE="$TARGET_DIR/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  # Remove UserPromptSubmit hooks matching skill-gate
  if jq -e '.hooks.UserPromptSubmit' "$SETTINGS_FILE" > /dev/null 2>&1; then
    TMP_FILE=$(mktemp)
    jq '
      .hooks.UserPromptSubmit |= [
        .[] | .hooks |= [
          .[] | select(
            .command != ".claude/hooks/skill-first-check.sh" and
            .command != ".claude/hooks/skill-queue.sh" and
            .command != ".claude/hooks/token-guardrail.sh"
          )
        ] | select(.hooks | length > 0)
      ]
      | if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end
    ' "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"
    echo "Removed UserPromptSubmit hooks from settings.json"
  fi

  # Remove PostCompact hook
  if jq -e '.hooks.PostCompact' "$SETTINGS_FILE" > /dev/null 2>&1; then
    TMP_FILE=$(mktemp)
    jq '
      .hooks.PostCompact |= [
        .[] | .hooks |= [
          .[] | select(.command != ".claude/hooks/post-compact-remind.sh")
        ] | select(.hooks | length > 0)
      ]
      | if .hooks.PostCompact == [] then del(.hooks.PostCompact) else . end
    ' "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"
    echo "Removed PostCompact hook from settings.json"
  fi

  # Clean up empty hooks object and empty file
  TMP_FILE=$(mktemp)
  jq 'if .hooks == {} then del(.hooks) else . end' "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"

  # Remove settings.json if empty
  if [ "$(jq 'keys | length' "$SETTINGS_FILE")" -eq 0 ]; then
    rm "$SETTINGS_FILE"
    echo "Removed empty settings.json"
  fi
fi

# Clean empty directories
rmdir "$TARGET_DIR/.claude/hooks" 2>/dev/null && echo "Removed empty hooks/" || true

echo ""
echo "Skill-Gate uninstalled."
echo "Note: Context files in .claude/context/ were preserved."
echo "Restart Claude Code or visit /hooks to reload settings."
