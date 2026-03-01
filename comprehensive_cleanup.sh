#!/bin/bash

# Comprehensive Repository Cleanup Script for JO Service
# Removes all redundant and unnecessary files

echo "=== JO Service Comprehensive Repository Cleanup ==="
echo ""

# Check if we're in the correct directory
if [ ! -f "server/package.json" ] && [ ! -f "jo_service_app/pubspec.yaml" ]; then
    echo "Error: Please run this script from the repository root directory"
    exit 1
fi

# Step 1: Remove large file from root
echo "Step 1: Removing large files from root directory..."
if [ -f "objects.txt" ]; then
    rm -f objects.txt
    echo "✓ Removed objects.txt (4.5MB)"
else
    echo "✓ objects.txt not found"
fi

# Step 2: Remove redundant files from root
echo ""
echo "Step 2: Removing redundant files from root directory..."
declare -a ROOT_FILES=(
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

REMOVED_ROOT=0
for file in "${ROOT_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "✓ Removed $file"
        REMOVED_ROOT=$((REMOVED_ROOT + 1))
    fi
done
echo "✓ Removed $REMOVED_ROOT files from root"

# Step 3: Remove redundant directories from root
echo ""
echo "Step 3: Removing redundant directories from root..."
declare -a ROOT_DIRS=(
    "memory-bank"
    ".vscode"
)

DIR_REMOVED=0
for dir in "${ROOT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "✓ Removed $dir"
        DIR_REMOVED=$((DIR_REMOVED + 1))
    fi
done
echo "✓ Removed $DIR_REMOVED directories from root"

# Step 4: Remove test files from server directory
echo ""
echo "Step 4: Removing test and debug files from server directory..."
declare -a SERVER_FILES=(
    "SETUP_VERIFICATION.md"
    "VERIFICATION_SETUP.md"
    "debug.js"
    "test-server.js"
    "test-verification.js"
    "test-verification-fixed.js"
)

REMOVED_SERVER=0
for file in "${SERVER_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "✓ Removed $file"
        REMOVED_SERVER=$((REMOVED_SERVER + 1))
    fi
done
echo "✓ Removed $REMOVED_SERVER files from server directory"

# Step 5: Check for other unnecessary files
echo ""
echo "Step 5: Checking for other unnecessary files..."

# Check for backup files
BACKUP_COUNT=$(find . -maxdepth 3 -name "*.backup*" -o -name "*.bak" -o -name "*.swp" -o -name "*~" 2>/dev/null | wc -l)
if [ $BACKUP_COUNT -gt 0 ]; then
    find . -maxdepth 3 -name "*.backup*" -o -name "*.bak" -o -name "*.swp" -o -name "*~" 2>/dev/null | xargs rm -f
    echo "✓ Removed $BACKUP_COUNT backup files"
fi

# Check for log files
LOG_COUNT=$(find . -maxdepth 3 -name "*.log" 2>/dev/null | wc -l)
if [ $LOG_COUNT -gt 0 ]; then
    find . -maxdepth 3 -name "*.log" 2>/dev/null | xargs rm -f
    echo "✓ Removed $LOG_COUNT log files"
fi

# Step 6: Show disk space savings
echo ""
echo "Step 6: Disk space savings:"
echo "  - objects.txt: ~4.5MB"
echo "  - Root files: ~15 files"
echo "  - Root directories: 2 directories"
echo "  - Server files: ~6 files"
echo "  - Backup files: ~$BACKUP_COUNT files"
echo "  - Log files: ~$LOG_COUNT files"
echo "  - Total estimated savings: ~5-10MB"
echo ""

# Step 7: Show remaining files in root
echo "Step 7: Remaining files in repository root:"
echo ""
ls -lh
echo ""

# Step 8: Show what needs to be committed
echo "Step 8: Files staged for commit:"
git status --short
echo ""

# Step 9: Create a commit to remove these files
echo "Step 9: Creating commit to remove redundant files..."
git add -A
git commit -m "Remove redundant and unnecessary files

- Remove objects.txt (4.5MB)
- Remove temporary deployment scripts
- Remove AI agent reference files
- Remove test and debug files (server and root)
- Remove memory-bank directory
- Remove .vscode directory
- Remove backup files and logs
- Remove redundant documentation files
- Clean up entire repository structure
- Reduce repository size for faster operations"

echo ""
echo "=== Cleanup Complete ==="
echo ""
echo "Next Steps:"
echo "1. Review the changes with: git status"
echo "2. Push to remote with: git push"
echo ""
echo "Note: The repository should now be much cleaner and smaller"
echo ""
