#!/bin/bash
# Skill-Gate Installer
# Copies skills, hook, and wires settings.json for your Claude Code project
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-.}"

echo "Skill-Gate Installer"
echo "===================="
echo "Target: $(cd "$TARGET_DIR" && pwd)"
echo ""

# Check target has .claude directory
if [ ! -d "$TARGET_DIR/.claude" ]; then
  echo "Creating .claude/ directory..."
  mkdir -p "$TARGET_DIR/.claude"
fi

# Copy skills
echo "Installing skills..."
mkdir -p "$TARGET_DIR/.claude/skills"
cp -r "$SCRIPT_DIR/skills/skill-first" "$TARGET_DIR/.claude/skills/"
cp -r "$SCRIPT_DIR/skills/context" "$TARGET_DIR/.claude/skills/"
echo "  - skill-first (router)"
echo "  - context (session persistence)"

# Copy hook
echo "Installing hook..."
mkdir -p "$TARGET_DIR/.claude/hooks"
cp "$SCRIPT_DIR/hooks/skill-first-check.sh" "$TARGET_DIR/.claude/hooks/"
chmod +x "$TARGET_DIR/.claude/hooks/skill-first-check.sh"
echo "  - skill-first-check.sh"

# Wire settings.json
SETTINGS_FILE="$TARGET_DIR/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  # Check if hook already exists
  if jq -e '.hooks.UserPromptSubmit' "$SETTINGS_FILE" > /dev/null 2>&1; then
    echo ""
    echo "WARNING: $SETTINGS_FILE already has UserPromptSubmit hooks."
    echo "Please manually merge the hook from examples/settings.json"
    echo ""
  else
    # Merge hook into existing settings
    TMP_FILE=$(mktemp)
    jq '.hooks = (.hooks // {}) + {
      "UserPromptSubmit": [{
        "hooks": [{
          "type": "command",
          "command": ".claude/hooks/skill-first-check.sh",
          "timeout": 5,
          "statusMessage": "Checking project skills..."
        }]
      }]
    }' "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"
    echo "  - Hook wired in settings.json"
  fi
else
  cp "$SCRIPT_DIR/examples/settings.json" "$SETTINGS_FILE"
  echo "  - Created settings.json with hook"
fi

# Create context directories
echo "Setting up context directories..."
mkdir -p "$TARGET_DIR/.claude/context/active"
mkdir -p "$TARGET_DIR/.claude/context/archive"

if [ ! -f "$TARGET_DIR/.claude/context/_index.md" ]; then
  cat > "$TARGET_DIR/.claude/context/_index.md" << 'EOF'
# Context Index

Last updated: (not yet)

## Active Context Files

| File | Topic Tags | Priority | Created | Summary |
|------|------------|----------|---------|---------|

## Archived Context Files

| File | Topic Tags | Created | Summary |
|------|------------|---------|---------|

## Quick Search

### By Topic

### By File Modified
EOF
  echo "  - Created context index"
fi

echo ""
echo "Done! Skill-Gate is installed."
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code or visit /hooks to reload settings"
echo "  2. Try asking Claude to implement something — it should check skills first"
echo "  3. Say 'save context' to test context persistence"
echo ""
echo "To uninstall: bash $(cd "$SCRIPT_DIR" && pwd)/uninstall.sh $TARGET_DIR"
