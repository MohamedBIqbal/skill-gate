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
if [ -f "$TARGET_DIR/.claude/hooks/skill-first-check.sh" ]; then
  rm "$TARGET_DIR/.claude/hooks/skill-first-check.sh"
  echo "Removed: hooks/skill-first-check.sh"
fi

if [ -f "$TARGET_DIR/.claude/hooks/post-compact-remind.sh" ]; then
  rm "$TARGET_DIR/.claude/hooks/post-compact-remind.sh"
  echo "Removed: hooks/post-compact-remind.sh"
fi

# Clean hooks from settings.json
SETTINGS_FILE="$TARGET_DIR/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  # Remove UserPromptSubmit hook
  if jq -e '.hooks.UserPromptSubmit' "$SETTINGS_FILE" > /dev/null 2>&1; then
    TMP_FILE=$(mktemp)
    jq 'del(.hooks.UserPromptSubmit[] | select(.hooks[].command == ".claude/hooks/skill-first-check.sh"))
        | if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end' "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"
    echo "Removed UserPromptSubmit hook from settings.json"
  fi

  # Remove PostCompact hook
  if jq -e '.hooks.PostCompact' "$SETTINGS_FILE" > /dev/null 2>&1; then
    TMP_FILE=$(mktemp)
    jq 'del(.hooks.PostCompact[] | select(.hooks[].command == ".claude/hooks/post-compact-remind.sh"))
        | if .hooks.PostCompact == [] then del(.hooks.PostCompact) else . end' "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"
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
