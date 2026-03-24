#!/bin/bash
# lib.sh - Shared helpers for HRBP lifecycle scripts
# Source this file: source "$(dirname "$0")/../../hrbp-common/scripts/lib.sh"

# Validate agent-id format: lowercase alphanumeric + hyphens, no leading/trailing hyphens, max 63 chars (DNS label).
validate_agent_id() {
  local id="$1"
  if ! printf '%s\n' "$id" | grep -Eq '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$'; then
    echo "❌ Invalid agent-id: $id"
    echo "   Expected: lowercase letters, numbers, hyphens; no leading/trailing hyphens; max 63 chars"
    echo "   Example: customer-service-a"
    exit 1
  fi
}

# 向 workspace 的 TOOLS.md 追加本地文件操作规范（幂等）
inject_file_edit_guide() {
  local tools_md="$1"
  [ -f "$tools_md" ] || return 0
  grep -q "## 本地文件操作规范" "$tools_md" && return 0
  cat >> "$tools_md" << 'GUIDE'

## 本地文件操作规范

1. **小改动优先**：read 最新文件内容后，复制原文精确片段再 edit
2. **大改动直接**：整文件重写走 write（先基于最新内容生成）
3. **避免一次改太大**：拆成多个小 patch，减少 mismatch
4. **以 read 结果为准**：别依赖聊天里渲染后的文本（如超链接形式的文件名），要以 read 工具的返回结果为准
GUIDE
}
