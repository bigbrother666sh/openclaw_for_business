#!/bin/bash
# 重新安装 Gateway Daemon 以更新环境变量
# 支持 macOS (LaunchAgent)、Linux (systemd)、Windows (Task Scheduler)

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_DIR="$PROJECT_ROOT/workspace"

export OPENCLAW_STATE_DIR="$WORKSPACE_DIR/data"
export OPENCLAW_CONFIG_PATH="$WORKSPACE_DIR/config/openclaw.json"
export OPENCLAW_OAUTH_DIR="$WORKSPACE_DIR/data/credentials"

echo "🔧 Reinstalling Gateway Daemon..."
echo "   State: $OPENCLAW_STATE_DIR"

cd "$PROJECT_ROOT/openclaw"

# 卸载现有的 daemon
pnpm openclaw daemon uninstall 2>/dev/null || true

# 重新安装（会使用当前环境变量，自动检测操作系统）
pnpm openclaw daemon install

echo ""
echo "✅ Daemon reinstalled"
echo ""
echo "Now open http://127.0.0.1:18789 to use"
