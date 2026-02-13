#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "🔄 Updating OpenClaw upstream..."

cd openclaw

# 拉取最新代码
git pull origin main

# 安装依赖（如果 package.json 有变化）
pnpm install

# 重新构建
pnpm build

cd ..

# 应用补丁（如果有）
if [ -d "patches" ] && [ "$(ls -A patches/*.patch 2>/dev/null)" ]; then
  ./scripts/apply-patches.sh
fi

echo ""
echo "✅ Update complete!"
echo ""
echo "Next steps:"
echo "  1. ./scripts/reinstall-daemon.sh  # 如果有配置变化"
echo "  2. ./scripts/dev.sh gateway       # 启动"
