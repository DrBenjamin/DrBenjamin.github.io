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

# Test 2: Source repository accessibility (both courses)
echo ""
echo "📋 Test 2: Source repository accessibility"
echo "-----------------------------------------"

ANALYTICAL_SRC="https://raw.githubusercontent.com/DrBenjamin/Analytical-Skills-for-Business/main/Analytical_Skills_for_Business.html"
DATA_SCI_SRC="https://raw.githubusercontent.com/DrBenjamin/Data-Science-and-Data-Analytics/main/Data_Science_and_Data_Analytics.html"

for SRC in "$ANALYTICAL_SRC" "$DATA_SCI_SRC"; do
  NAME=$(basename "$SRC")
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SRC")
  if [ "$HTTP_STATUS" = "200" ]; then
      echo "✅ $NAME accessible (HTTP $HTTP_STATUS)"
  else
      echo "⚠️  $NAME not accessible (HTTP $HTTP_STATUS) — if this file is optional it will simply be skipped by the workflow"
  fi
done

# Test 3: Content download functionality (size + hash)
echo ""
echo "📋 Test 3: Content download functionality"
echo "----------------------------------------"

tmpdir=$(mktemp -d)
for SRC in "$ANALYTICAL_SRC" "$DATA_SCI_SRC"; do
  NAME=$(basename "$SRC")
  DEST="$tmpdir/$NAME"
  curl -s "$SRC" -o "$DEST"
  if [ -f "$DEST" ]; then
      SIZE=$(wc -c < "$DEST")
      if [ "$SIZE" -gt 800 ]; then
          if command -v shasum &> /dev/null; then
            HASH=$(shasum -a 256 "$DEST" | cut -d' ' -f1)
            echo "✅ $NAME downloaded ($SIZE bytes) sha256=$HASH"
          else
            echo "✅ $NAME downloaded ($SIZE bytes)"
          fi
      else
          echo "⚠️  $NAME downloaded but size seems small ($SIZE bytes)"
      fi
  else
      echo "⚠️  Failed to download $NAME"
  fi
done
rm -rf "$tmpdir"

# Test 4: Change detection logic (per course file)
echo ""
echo "📋 Test 4: Change detection simulation"
echo "-------------------------------------"

for PAIR in \
    "${ANALYTICAL_SRC}::analytical-skills.html" \
    "${DATA_SCI_SRC}::data-science-analytics.html"; do
    SRC_URL="${PAIR%%::*}"
    LOCAL_FILE="${PAIR##*::}"
    BASENAME=$(basename "$SRC_URL")
    echo ""
    echo "▶ Checking $LOCAL_FILE vs source $BASENAME"
    curl -s "$SRC_URL" -o fresh.tmp || true
    if [ ! -f fresh.tmp ]; then
        echo "⚠️  Skipping $LOCAL_FILE (source fetch failed)"
        continue
    fi
    if [ -f "$LOCAL_FILE" ]; then
        if cmp -s fresh.tmp "$LOCAL_FILE"; then
            echo "✅ No change ($LOCAL_FILE)"
        else
            echo "🔄 Would update ($LOCAL_FILE differs)"
            if command -v diff &>/dev/null; then
                echo "--- size comparison"
                echo -n "current: "; wc -c < "$LOCAL_FILE"
                echo -n "fresh:   "; wc -c < fresh.tmp
            fi
        fi
    else
        echo "🆕 $LOCAL_FILE missing locally (would be created)"
    fi
    rm -f fresh.tmp
done

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
echo "• Manual triggering from GitHub Actions tab (multi-repo sync)"
echo "• Per-file change detection for two course HTML files"
echo "• Static landing page preserved (not auto-overwritten)"
echo ""
echo "No manual setup required for basic functionality!"
echo ""
echo "To manually trigger an update:"
echo "1. Go to: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]//' | sed 's/.git$//')/actions"
echo "2. Click 'Update Course Content (Analytical + Data Science)'"
echo "3. Click 'Run workflow' → 'Run workflow'"
echo ""
echo "For advanced real-time updates, see GITHUB_ACTIONS_SETUP.md"