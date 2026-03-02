#!/bin/bash
# setup-crew.sh - 多 Agent 系统安装脚本
# 将 crew/ 中的 workspace 模板、共享协议、角色模板部署�� ~/.openclaw/
# 幂等设计：已存在的 workspace 不会覆盖（除非 --force）
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CREW_DIR="$PROJECT_ROOT/crew"
OPENCLAW_HOME="$HOME/.openclaw"
CONFIG_PATH="$OPENCLAW_HOME/openclaw.json"
FORCE=false

[ "$1" = "--force" ] && FORCE=true

if [ ! -d "$CREW_DIR" ]; then
  echo "❌ crew/ directory not found at $CREW_DIR"
  exit 1
fi

echo "📦 Setting up Agent System (crew)..."

# ─── 1. 安装内置 Agent workspace（main + hrbp） ─────────────────
for agent_dir in "$CREW_DIR"/workspaces/*/; do
  [ -d "$agent_dir" ] || continue
  agent_id="$(basename "$agent_dir")"
  dest="$OPENCLAW_HOME/workspace-$agent_id"

  if [ -d "$dest" ] && [ "$FORCE" != "true" ]; then
    echo "  ⚠️  workspace-$agent_id already exists, skipping (use --force to overwrite)"
    continue
  fi

  mkdir -p "$dest"
  cp "$agent_dir"*.md "$dest/"
  # 复制 Agent 专属 skills（���有）
  if [ -d "$agent_dir/skills" ]; then
    cp -r "$agent_dir/skills" "$dest/"
  fi
  echo "  ✅ workspace-$agent_id installed"
done

# ─── 2. 复制共享协议到每个已安装的 workspace ─────────────────────
for agent_dir in "$CREW_DIR"/workspaces/*/; do
  [ -d "$agent_dir" ] || continue
  agent_id="$(basename "$agent_dir")"
  dest="$OPENCLAW_HOME/workspace-$agent_id"
  if [ -d "$dest" ] && [ -d "$CREW_DIR/shared" ]; then
    cp "$CREW_DIR/shared/"*.md "$dest/"
  fi
done
echo "  ✅ Shared protocols (RULES.md, TEMPLATES.md) copied"

# ─── 3. 安装角色模板 ────────────────────────────────────────────���─
if [ -d "$CREW_DIR/role-templates" ]; then
  ROLE_DEST="$OPENCLAW_HOME/hrbp-templates"
  mkdir -p "$ROLE_DEST"
  cp -r "$CREW_DIR/role-templates/"* "$ROLE_DEST/"
  echo "  ✅ Role templates installed to $ROLE_DEST"
fi

# ─── 4. 更新 openclaw.json（如果 agents.list 尚未配置） ──────────
if [ -f "$CONFIG_PATH" ]; then
  if node -e "
    const c = JSON.parse(require('fs').readFileSync('$CONFIG_PATH','utf8'));
    process.exit(c.agents?.list?.length > 0 ? 0 : 1);
  " 2>/dev/null; then
    echo "  ⚠️  agents.list already configured in openclaw.json, skipping"
  else
    echo "  📝 Merging agent config into openclaw.json..."
    node -e "
      const fs = require('fs');
      const c = JSON.parse(fs.readFileSync('$CONFIG_PATH','utf8'));
      if (!c.agents) c.agents = {};
      c.agents.list = [
        {
          id: 'main',
          default: true,
          name: 'Main Agent',
          workspace: '~/.openclaw/workspace-main',
          subagents: { allowAgents: ['main', 'hrbp'] }
        },
        {
          id: 'hrbp',
          name: 'HRBP',
          workspace: '~/.openclaw/workspace-hrbp'
        }
      ];
      if (!c.bindings) c.bindings = [];
      fs.writeFileSync('$CONFIG_PATH', JSON.stringify(c, null, 2) + '\n');
    "
    echo "  ✅ openclaw.json updated"
  fi
else
  echo "  ⚠️  openclaw.json not found at $CONFIG_PATH"
  echo "     Will be created on first start (dev.sh / reinstall-daemon.sh)"
fi

# ─── 5. 完成 ──────────────────────────────────────────────────────
echo ""
echo "✅ Agent System installed!"
echo ""
echo "Installed locations:"
echo "  Workspaces:  $OPENCLAW_HOME/workspace-main/, workspace-hrbp/"
echo "  Templates:   $OPENCLAW_HOME/hrbp-templates/"
echo "  Config:      $CONFIG_PATH"
