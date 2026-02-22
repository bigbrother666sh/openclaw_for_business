#!/bin/bash
set -e

cd "$(dirname "$0")/.."

PATCHES_DIR="patches"

if [ ! -d "$PATCHES_DIR" ]; then
  echo "⚠️  No patches directory found"
  exit 0
fi

echo "📦 Applying patches..."

cd openclaw

# 先恢复到干净的 upstream 状态，避免重复应用补丁导致失败
git checkout -- . 2>/dev/null || true

for patch in ../$PATCHES_DIR/*.patch; do
  if [ -f "$patch" ]; then
    echo "  → $(basename "$patch")"
    git apply --ignore-whitespace --whitespace=fix "$patch" || {
      echo "❌ Failed to apply $(basename "$patch")"
      exit 1
    }
  fi
done

# Sync lockfile after git patches
echo "📦 Syncing dependencies..."
pnpm install --frozen-lockfile=false

cd ..

echo "✅ All patches applied"
