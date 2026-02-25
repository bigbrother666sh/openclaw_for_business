#!/bin/bash
# apply-addons.sh - 通用 addon 加载器
# 扫描 addons/*/ 目录，对每个 addon 依次执行：
#   1. overrides.sh  — pnpm overrides / 依赖替换（高稳健性）
#   2. patches/*.patch — git patch（逻辑新增，需精确匹配）
#   3. skills/*/SKILL.md — 自定义 skill 安装
#
# addon 目录结构：
#   addons/<name>/
#   ├── addon.json          # 元数据（名称、版本、描述）
#   ├── overrides.sh        # 可选：依赖替换脚本
#   ├── patches/*.patch     # 可选：git 补丁
#   └── skills/*/SKILL.md   # 可选：自定义技能
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDONS_DIR="$PROJECT_ROOT/addons"
OPENCLAW_DIR="$PROJECT_ROOT/openclaw"

if [ ! -d "$ADDONS_DIR" ] || [ -z "$(ls -A "$ADDONS_DIR" 2>/dev/null)" ]; then
  echo "📦 No addons found, skipping"
  exit 0
fi

# 恢复上游到干净状态（清除之前应用的补丁和 overrides）
cd "$OPENCLAW_DIR"
git checkout -- . 2>/dev/null || true
cd "$PROJECT_ROOT"

ADDON_COUNT=0

for addon_dir in "$ADDONS_DIR"/*/; do
  [ -d "$addon_dir" ] || continue

  addon_name="$(basename "$addon_dir")"

  # 跳过没有 addon.json 的目录
  if [ ! -f "$addon_dir/addon.json" ]; then
    echo "⚠️  Skipping $addon_name (no addon.json)"
    continue
  fi

  echo "📦 Loading addon: $addon_name"
  ADDON_COUNT=$((ADDON_COUNT + 1))

  # ─── 第一层：overrides（依赖替换，不依赖行号） ──────────────
  if [ -f "$addon_dir/overrides.sh" ]; then
    echo "  🔧 Running overrides..."
    ADDON_DIR="$addon_dir" OPENCLAW_DIR="$OPENCLAW_DIR" bash "$addon_dir/overrides.sh"
  fi

  # ─── 第二层：git patches（精确代码改动） ─────────────────────
  if ls "$addon_dir"/patches/*.patch 1>/dev/null 2>&1; then
    echo "  🩹 Applying patches..."
    cd "$OPENCLAW_DIR"
    for patch in "$addon_dir"/patches/*.patch; do
      echo "    → $(basename "$patch")"
      git apply --3way --ignore-whitespace --whitespace=fix "$patch" || {
        echo "    ❌ Failed to apply $(basename "$patch")"
        echo "       Hint: 上游代码可能已变更，需在 $addon_name 中重新生成此补丁"
        exit 1
      }
    done
    cd "$PROJECT_ROOT"
  fi

  # ─── 第三层：skills 安装 ─────────────────────────────────────
  if [ -d "$addon_dir/skills" ]; then
    echo "  📚 Installing skills..."
    for skill_dir in "$addon_dir"/skills/*/; do
      if [ -f "${skill_dir}SKILL.md" ]; then
        skill_name="$(basename "$skill_dir")"
        echo "    → $skill_name"
        cp -r "$skill_dir" "$OPENCLAW_DIR/skills/$skill_name"
      fi
    done
  fi

  echo "  ✅ $addon_name loaded"
done

# 所有 addon 加载完成后统一安装依赖
if [ "$ADDON_COUNT" -gt 0 ]; then
  echo "📦 Syncing dependencies..."
  cd "$OPENCLAW_DIR"
  pnpm install --frozen-lockfile=false
  cd "$PROJECT_ROOT"
fi

echo "✅ All addons applied ($ADDON_COUNT loaded)"
