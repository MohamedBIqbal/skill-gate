#!/bin/bash
# Skill-Gate Installer
# Copies skills, hooks, and wires settings.json for your Claude Code project
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
echo "  - skill-first (router with queue protocol)"
echo "  - context (session persistence)"

# Copy hooks
echo "Installing hooks..."
mkdir -p "$TARGET_DIR/.claude/hooks"
cp "$SCRIPT_DIR/hooks/skill-queue.sh" "$TARGET_DIR/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/build-skill-index.sh" "$TARGET_DIR/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/token-guardrail.sh" "$TARGET_DIR/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/post-compact-remind.sh" "$TARGET_DIR/.claude/hooks/"
cp "$SCRIPT_DIR/hooks/skill-phases.conf.example" "$TARGET_DIR/.claude/hooks/"
chmod +x "$TARGET_DIR/.claude/hooks/skill-queue.sh"
chmod +x "$TARGET_DIR/.claude/hooks/build-skill-index.sh"
chmod +x "$TARGET_DIR/.claude/hooks/token-guardrail.sh"
chmod +x "$TARGET_DIR/.claude/hooks/post-compact-remind.sh"
echo "  - skill-queue.sh (UserPromptSubmit — keyword matching + queue protocol)"
echo "  - build-skill-index.sh (index generator — auto-rebuilds on changes)"
echo "  - token-guardrail.sh (UserPromptSubmit — cost-awareness warnings)"
echo "  - post-compact-remind.sh (PostCompact — re-injects skill awareness)"
echo "  - skill-phases.conf.example (phase ordering template)"

# Also keep legacy hook for users who prefer the simpler version
cp "$SCRIPT_DIR/hooks/skill-first-check.sh" "$TARGET_DIR/.claude/hooks/"
chmod +x "$TARGET_DIR/.claude/hooks/skill-first-check.sh"
echo "  - skill-first-check.sh (legacy — flat list, no queue)"

# Build initial skill index
echo "Building skill index..."
(cd "$TARGET_DIR" && ".claude/hooks/build-skill-index.sh" 2>/dev/null) || echo "  (will auto-build on first prompt)"

# Wire settings.json
SETTINGS_FILE="$TARGET_DIR/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  # Check if hooks already exist
  HAS_PROMPT_HOOK=$(jq -e '.hooks.UserPromptSubmit' "$SETTINGS_FILE" > /dev/null 2>&1 && echo "yes" || echo "no")
  HAS_COMPACT_HOOK=$(jq -e '.hooks.PostCompact' "$SETTINGS_FILE" > /dev/null 2>&1 && echo "yes" || echo "no")

  if [ "$HAS_PROMPT_HOOK" = "yes" ] || [ "$HAS_COMPACT_HOOK" = "yes" ]; then
    echo ""
    [ "$HAS_PROMPT_HOOK" = "yes" ] && echo "WARNING: settings.json already has UserPromptSubmit hooks."
    [ "$HAS_COMPACT_HOOK" = "yes" ] && echo "WARNING: settings.json already has PostCompact hooks."
    echo "Please manually merge hooks from examples/settings.json"
    echo ""
  else
    # Merge hooks into existing settings
    TMP_FILE=$(mktemp)
    jq '.hooks = (.hooks // {}) + {
      "UserPromptSubmit": [{
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/skill-queue.sh",
            "timeout": 5,
            "statusMessage": "Matching skills..."
          },
          {
            "type": "command",
            "command": ".claude/hooks/token-guardrail.sh",
            "timeout": 5,
            "statusMessage": "Checking token efficiency..."
          }
        ]
      }],
      "PostCompact": [{
        "hooks": [{
          "type": "command",
          "command": ".claude/hooks/post-compact-remind.sh",
          "timeout": 5,
          "statusMessage": "Re-injecting skill awareness..."
        }]
      }]
    }' "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"
    echo "  - All hooks wired in settings.json"
  fi
else
  cp "$SCRIPT_DIR/examples/settings.json" "$SETTINGS_FILE"
  echo "  - Created settings.json with hooks"
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
echo "Done! Skill-Gate v2 is installed."
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code or visit /hooks to reload settings"
echo "  2. (Optional) Copy skill-phases.conf.example → skill-phases.conf and customize phases"
echo "  3. Try asking Claude to implement something — it should check skills first"
echo "  4. For multi-skill tasks, Claude will use subagent delegation instead of loading all skills"
echo ""
echo "To uninstall: bash $(cd "$SCRIPT_DIR" && pwd)/uninstall.sh $TARGET_DIR"
