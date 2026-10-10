#!/bin/bash
set -e

# Skills directory
SKILL_DIR="/Users/george/.trae-cn/assistant/.agents/skill"

# Enter the skills directory
cd "$SKILL_DIR"

# Stage all changes
git add .

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "No changes to sync"
    exit 0
fi

# Commit changes
git commit -m "chore: weekly skills sync $(date +%Y-%m-%d)"

# Push to remote
git push origin main

echo "Sync completed successfully"
