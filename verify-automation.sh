#!/bin/bash

# GitHub Actions Automation Verification Script
# This script tests the core automation functionality without making any changes

echo "🔍 GitHub Actions Automation Verification"
echo "========================================"
echo ""

# Check if we're in the right repository
if [ ! -f ".github/workflows/update-content.yml" ]; then
    echo "❌ Error: Not in the correct repository or workflow file missing"
    echo "   Expected: .github/workflows/update-content.yml"
    exit 1
fi

echo "✅ Repository structure verified"

# Test 1: Check workflow file syntax
echo ""
echo "📋 Test 1: Workflow file validation"
echo "-----------------------------------"

if command -v python3 &> /dev/null; then
    python3 -c "
import yaml
import sys
try:
    with open('.github/workflows/update-content.yml', 'r') as f:
        yaml.safe_load(f)
    print('✅ Workflow YAML syntax is valid')
except Exception as e:
    print(f'❌ Workflow YAML syntax error: {e}')
    sys.exit(1)
"
else
    echo "⚠️  Python not available for YAML validation, skipping syntax check"
fi

# Test 2: Source repository accessibility
echo ""
echo "📋 Test 2: Source repository accessibility"
echo "-----------------------------------------"

SOURCE_URL="https://raw.githubusercontent.com/DrBenjamin/Analytical-Skills-for-Business/main/Analytical_Skills_for_Business.html"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SOURCE_URL")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Source repository is accessible (HTTP $HTTP_STATUS)"
else
    echo "❌ Source repository not accessible (HTTP $HTTP_STATUS)"
    echo "   This may affect automatic content updates"
fi

# Test 3: Content download functionality
echo ""
echo "📋 Test 3: Content download functionality"
echo "----------------------------------------"

curl -s "$SOURCE_URL" -o test-download.html

if [ -f test-download.html ]; then
    SIZE=$(wc -c < test-download.html)
    if [ "$SIZE" -gt 1000 ]; then
        echo "✅ Content download successful ($SIZE bytes)"
    else
        echo "❌ Downloaded content seems too small ($SIZE bytes)"
        echo "   This may indicate an issue with the source file"
    fi
    rm test-download.html
else
    echo "❌ Failed to download content"
fi

# Test 4: Change detection logic
echo ""
echo "📋 Test 4: Change detection simulation"
echo "-------------------------------------"

if [ -f index.html ]; then
    CURRENT_SIZE=$(wc -c < index.html)
    echo "📊 Current site content: $CURRENT_SIZE bytes"
    
    # Download fresh content for comparison
    curl -s "$SOURCE_URL" -o fresh-content.html
    if [ -f fresh-content.html ]; then
        FRESH_SIZE=$(wc -c < fresh-content.html)
        echo "📊 Source content: $FRESH_SIZE bytes"
        
        if cmp -s fresh-content.html index.html; then
            echo "✅ Content is identical - no update needed"
        else
            echo "🔄 Content differs - update would be triggered"
        fi
        rm fresh-content.html
    fi
else
    echo "⚠️  No current index.html found"
fi

# Test 5: GitHub Actions workflow permissions
echo ""
echo "📋 Test 5: Workflow permissions check"
echo "-------------------------------------"

if grep -q "contents: write" .github/workflows/update-content.yml; then
    echo "✅ Content write permissions configured"
else
    echo "⚠️  Content write permissions may not be configured"
fi

if grep -q "pages: write" .github/workflows/update-content.yml; then
    echo "✅ Pages write permissions configured"
else
    echo "⚠️  Pages write permissions may not be configured"
fi

# Summary
echo ""
echo "📊 Verification Summary"
echo "======================"
echo ""
echo "The automation should work automatically with:"
echo "• Daily scheduled updates (6 AM UTC)"
echo "• Manual triggering from GitHub Actions tab"
echo "• Automatic Jekyll deployment"
echo ""
echo "No manual setup required for basic functionality!"
echo ""
echo "To manually trigger an update:"
echo "1. Go to: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]//' | sed 's/.git$//')/actions"
echo "2. Click 'Update Content from Analytical Skills Repository'"
echo "3. Click 'Run workflow' → 'Run workflow'"
echo ""
echo "For advanced real-time updates, see GITHUB_ACTIONS_SETUP.md"