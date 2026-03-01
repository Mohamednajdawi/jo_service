#!/bin/bash

# Remove Redundant Files from JO Service Repository
# This script removes unnecessary files to reduce repository size

echo "=== JO Service Repository Cleanup - Removing Redundant Files ==="
echo ""

# Check if we're in the correct directory
if [ ! -f "package.json" ]; then
    echo "Error: Please run this script from the repository root directory"
    exit 1
fi

# List of files and directories to remove
declare -a FILES_TO_REMOVE=(
    "objects.txt"
    "cleanup_repository.sh"
    "cleanup_simple.sh"
    "deploy_to_railway.sh"
    ".git-config-backup.txt"
    "RAILWAY_CHECKLIST.md"
    "RAILWAY_DEPLOYMENT_GUIDE.md"
    "DEPLOYMENT_README.md"
    "AI_AGENT_REFERENCE.md"
    "VERIFICATION_FIXES_SUMMARY.md"
    "test_push_notifications.md"
    "SETUP_VERIFICATION.md"
    "VERIFICATION_SETUP.md"
    "debug.js"
    "test-server.js"
    "test-verification.js"
    "test-verification-fixed.js"
)

declare -a DIRS_TO_REMOVE=(
    "memory-bank"
    ".vscode"
)

# Step 1: Remove large file
echo "Step 1: Removing large files..."
if [ -f "objects.txt" ]; then
    rm -f objects.txt
    echo "✓ Removed objects.txt (4.5MB)"
else
    echo "✓ objects.txt not found"
fi

# Step 2: Remove redundant files
echo ""
echo "Step 2: Removing redundant files..."
REMOVED_COUNT=0

for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "✓ Removed $file"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    else
        echo "✗ $file not found"
    fi
done

echo ""
echo "✓ Removed $REMOVED_COUNT redundant files"

# Step 3: Remove redundant directories
echo ""
echo "Step 3: Removing redundant directories..."
DIR_REMOVED_COUNT=0

for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "✓ Removed $dir"
        DIR_REMOVED_COUNT=$((DIR_REMOVED_COUNT + 1))
    else
        echo "✗ $dir not found"
    fi
done

echo ""
echo "✓ Removed $DIR_REMOVED_COUNT redundant directories"

# Step 4: Show disk space savings
echo ""
echo "Step 4: Disk space savings:"
echo "  - objects.txt: ~4.5MB"
echo "  - Redundant files: ~15-20 files"
echo "  - Redundant directories: 2 directories"
echo "  - Total estimated savings: ~5-10MB"
echo ""

# Step 5: Show remaining files
echo "Step 5: Remaining files in repository root:"
echo ""
ls -lh
echo ""

# Step 6: Show what needs to be committed
echo "Step 6: Files staged for commit:"
git status --short
echo ""

# Step 7: Create a commit to remove these files
echo "Step 7: Creating commit to remove redundant files..."
git add -A
git commit -m "Remove redundant files and directories

- Remove objects.txt (4.5MB)
- Remove temporary deployment scripts
- Remove AI agent reference files
- Remove test and debug files
- Remove memory-bank directory
- Remove .vscode directory
- Clean up documentation files
- Reduce repository size for faster operations"

echo ""
echo "=== Cleanup Complete ==="
echo ""
echo "Next Steps:"
echo "1. Review the changes with: git status"
echo "2. Push to remote with: git push"
echo ""
echo "Note: The repository size should be significantly reduced now"
echo ""
