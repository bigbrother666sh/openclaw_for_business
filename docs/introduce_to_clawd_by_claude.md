# OpenClaw 企业化改造分析

> 此文档记录了对 OpenClaw 代码仓库的分析结果，用于企业业务场景改造参考。

## 项目概述

OpenClaw 是一个多通道 AI 网关系统，核心技术栈：
- **语言**: TypeScript (ESM) + Node.js 22+
- **消息框架**: grammyjs (Telegram), @slack/bolt (Slack), discord.js
- **向量数据库**: sqlite-vec
- **Web 框架**: Express 5.x

## 核心模块

| 模块 | 路径 | 功能 |
|------|------|------|
| Gateway 统一网关 | `src/gateway/` | WebSocket + HTTP 入口，40+ RPC 方法 |
| Agent 执行引擎 | `src/agents/` | Pi Agent 运行时，Auth profile 轮换 |
| 多通道路由 | `src/routing/` + `src/channels/` | 40+ 消息通道适配 |
| 向量存储 | `src/memory/` | 混合搜索（向量+BM25） |
| 插件系统 | `src/plugins/` | 可扩展 Plugin API |
| Skill 系统 | `src/agents/skills/` | 三层技能（内置/社区/自定义） |
| Hooks 事件 | `src/hooks/` | 生命周期钩子扩展点 |
| 定时任务 | `src/gateway/server-cron.ts` | Cron 调度 |

## 已有的企业级能力

- 多租户隔离（agent-scoped sessions）
- 审计日志（command-logger hook）
- 安全策略（DM pairing, allowlist, exec approval）
- 成本控制（usage tracking, provider switching）
- Model failover（多 Provider 轮换）

## 关键文件参考

| 功能 | 文件 |
|------|------|
| Gateway 启动 | `src/gateway/server.impl.ts` |
| Agent 执行 | `src/agents/pi-embedded-runner/run.ts` |
| 内存管理 | `src/memory/manager.ts` |
| 路由解析 | `src/routing/resolve-route.ts` |
| 配置 Schema | `src/config/zod-schema.js` |
| 协议定义 | `src/gateway/protocol/index.ts` |
| 插件类型 | `src/plugins/runtime/types.ts` |
| 频道适配 | `src/channels/plugins/types.plugin.ts` |

## 扩展点指南

### 新增业务 Skill
```typescript
// 在 src/agents/skills/ 下创建
export const marketResearchSkill = {
  id: "market-research",
  handler: async (input) => {
    // 调用外部数据 API
    // 存储到向量库
    // 返回分析结果
  }
};
```

### 新增 Hook
```typescript
// 在 src/hooks/ 下创建
api.on("chat:after", async (event) => {
  // 响应后处理：同步 CRM、记录日志等
});
```

### 新增定时任务
利用 `src/gateway/server-cron.ts` 的 cron 能力实现定时数据采集。

---

## 浏览器控制能力

### 已内置，基于 Playwright

配置启用（`~/.openclaw/openclaw.json`）：
```json
{
  "browser": {
    "enabled": true,
    "headless": false,
    "defaultProfile": "chrome"
  }
}
```

### 两种模式

| Profile | 说明 |
|---------|------|
| `openclaw` | OpenClaw 管理的隔离浏览器实例 |
| `chrome` | 接管现有 Chrome 标签页（需安装浏览器扩展） |

### Chrome 扩展安装

```bash
# 安装扩展到本地目录
openclaw browser extension install

# 查看安装路径
openclaw browser extension path
```

然后在 Chrome 中：`chrome://extensions` → 开发者模式 → 加载已解压的扩展程序

### 支持的操作

- `status` / `start` / `stop` - 浏览器生命周期
- `tabs` / `open` / `close` / `focus` - 标签页管理
- `navigate` - 导航到 URL
- `snapshot` - 获取页面 DOM 快照（用于 AI 理解页面）
- `screenshot` - 截图
- `act` - 执行操作（点击、输入、滚动等）
- `upload` / `dialog` - 文件上传和对话框处理
- `pdf` - 保存为 PDF

### 关键文件

| 功能 | 文件 |
|------|------|
| 浏览器工具 | `src/agents/tools/browser-tool.ts` |
| 浏览器配置 | `src/browser/config.ts` |
| 配置类型 | `src/config/types.browser.ts` |
| Chrome 扩展 | `assets/chrome-extension/` |
| 扩展文档 | `docs/tools/chrome-extension.md` |

---

## 设备/电脑控制能力（Node 机制）

### 通过 Node（节点）控制设备

| 能力 | 命令 | 平台 |
|------|------|------|
| 执行 Shell 命令 | `system.run` | macOS/Linux/Windows(WSL) |
| 系统通知 | `system.notify` | macOS/iOS/Android |
| 摄像头拍照/录像 | `camera.snap/clip` | macOS/iOS/Android |
| 屏幕录制 | `screen.record` | macOS/iOS/Android |
| 获取位置 | `location.get` | iOS/Android |
| 发送短信 | `sms.send` | Android |
| WebView 控制 | `canvas.*` | iOS/Android |

### Companion Apps

项目包含原生应用：
- **macOS**: `apps/macos/` - 菜单栏应用，以 Node 模式连接 Gateway
- **iOS**: `apps/ios/`
- **Android**: `apps/android/`

### Headless Node Host

在任意机器上运行（无 UI）：

```bash
# 在要被控制的机器上
openclaw node run --host <gateway-host> --port 18789 --display-name "My PC"

# 在 Gateway 端批准配对
openclaw nodes pending
openclaw nodes approve <requestId>
```

### 安全机制（Exec Approvals）

`system.run` 需要审批：

```bash
# 添加允许执行的命令到白名单
openclaw approvals allowlist add --node <id> "/usr/bin/open"
openclaw approvals allowlist add --node <id> "/usr/bin/osascript"
```

### 关键文件

| 功能 | 文件 |
|------|------|
| Nodes 工具 | `src/agents/tools/nodes-tool.ts` |
| Node Host | `src/node-host/runner.ts` |
| 系统命令定义 | `apps/shared/OpenClawKit/Sources/OpenClawKit/SystemCommands.swift` |
| Nodes 文档 | `docs/nodes/index.md` |

### 没有的能力

**没有内置桌面 GUI 自动化**（点击按钮、拖拽窗口、识别屏幕元素）。

需要通过 `system.run` 调用外部工具：
- **macOS**: AppleScript、`cliclick`
- **Windows**: AutoHotKey、PowerShell + UI Automation
- **Linux**: `xdotool`
- **跨平台**: PyAutoGUI、SikuliX

---

## 平台支持情况

| 平台 | Gateway + CLI | Companion App | Node Host |
|------|---------------|---------------|-----------|
| macOS | ✅ | ✅ 菜单栏应用 | ✅ |
| Linux | ✅ | ❌ | ✅ Headless |
| iOS | ❌ | ✅ | ✅ |
| Android | ❌ | ✅ | ✅ |
| **Windows** | ⚠️ WSL2 | ❌ 计划中 | ⚠️ WSL2 内 |

### Windows 限制

- Gateway + CLI 需通过 WSL2 运行
- 在 WSL2 中执行 `system.run` 是 Linux 命令，无法直接控制 Windows 原生应用
- 变通：从 WSL 调用 Windows 程序
  ```bash
  powershell.exe -Command "Get-Process"
  /mnt/c/Windows/System32/cmd.exe /c "echo hello"
  ```
- Windows 原生 Node Host 需要额外开发

---

## 知识库能力分析

### 内置向量检索系统（Memory）

项目内置了基于 `sqlite-vec` 的知识库系统，位于 `src/memory/`。

#### 架构

```
本地 .md 文件 → 分块（400 tokens/块，80 tokens 重叠）→ Embedding → sqlite-vec 存储
                                                                         ↓
Agent 调用 memory_search(query) → 混合检索（70% 向量 + 30% BM25）→ 返回相关片段
```

#### 数据库 Schema（`src/memory/memory-schema.ts`）

| 表 | 用途 |
|----|------|
| `files` | 跟踪源文件（路径、hash、修改时间） |
| `chunks` | 文本块 + embedding 向量 |
| `chunks_vec` | 向量相似度搜索（余弦距离） |
| `chunks_fts` | FTS5 全文搜索索引 |
| `embedding_cache` | embedding 缓存（按 provider/model/hash） |

#### Embedding 提供商

- **OpenAI**: `text-embedding-3-small`（默认）
- **Google Gemini**: `gemini-embedding-001`
- **Voyage AI**: `voyage-4-large`
- **本地**: `node-llama-cpp` + GGUF 模型（默认 `embeddinggemma-300M`）

#### Agent 工具

| 工具 | 用途 |
|------|------|
| `memory_search(query, maxResults?, minScore?)` | 语义搜索，返回路径、行号、片段、分数 |
| `memory_get(path, from?, lines?)` | 安全只读访问特定文件 |

#### 知识库来源

- `MEMORY.md` 或 `memory.md`（agent workspace 根目录）
- `/memory` 子目录（递归扫描所有 `.md` 文件）
- `memorySearch.extraPaths` 配置的额外路径（必须为 `.md`）

#### 当前限制

**仅支持 Markdown (.md) 文件**。`src/memory/internal.ts` 中硬编码了 `.md` 过滤。不支持 Word/PDF/Excel/TXT。

#### 配置示例

```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "enabled": true,
        "provider": "openai",
        "model": "text-embedding-3-small",
        "sources": ["memory", "sessions"],
        "extraPaths": ["/path/to/docs"],
        "chunking": { "tokens": 400, "overlap": 80 },
        "sync": { "watch": true, "onSearch": true }
      }
    }
  }
}
```

### 扩展支持 Word 文档

要让知识库支持 `.docx` 等格式，需改动 3 处：

1. **添加文档解析器** — 新建 `src/memory/parsers/docx-parser.ts`，用 `mammoth` 库提取文本
2. **修改文件发现逻辑** — `src/memory/internal.ts` 中扩展文件过滤，接受 `.docx`、`.pdf`、`.txt`
3. **统一内容提取管道** — `src/memory/manager.ts` 的 `indexFile()` 中按扩展名路由到不同解析器

核心索引/检索/Agent 调用链路无需改动。

---

## 飞书插件知识库方案分析

### 概述

飞书插件位于 `extensions/feishu/`（`@openclaw/feishu`），社区维护（@m1heng）。

### 方案：实时 API 调用（非预索引）

飞书插件 **不使用** 向量检索/RAG，采用 Agent 按需调用飞书 API 的方式：

```
Agent 需要知识 → 调用 feishu_wiki / feishu_doc → 实时请求飞书 API → 返回文档内容给 Agent
```

### 5 组工具

| 工具 | 文件 | 用途 |
|------|------|------|
| `feishu_wiki` | `extensions/feishu/src/wiki.ts` | 浏览知识库空间、列出节点层级、获取文档 token |
| `feishu_doc` | `extensions/feishu/src/docx.ts` | 读写文档内容（32 种 block 类型），支持 Markdown 互转 |
| `feishu_drive` | `extensions/feishu/src/drive.ts` | 云盘文件管理（列表、创建文件夹、移动、删除） |
| `feishu_bitable` | `extensions/feishu/src/bitable.ts` | 多维表格操作（查询/增删改记录，14+ 字段类型） |
| `feishu_perm` | `extensions/feishu/src/perm.ts` | 文档权限管理（默认关闭） |

### 典型工作流（知识库查询）

1. `feishu_wiki` → `spaces` → 列出所有知识库空间
2. `feishu_wiki` → `nodes` → 浏览文档树，拿到 `obj_token`
3. `feishu_doc` → `read`（传入 `obj_token`）→ 获取文档全文
4. Agent 基于文档内容推理和回答

### 连接方式

- **WebSocket**（默认）：长连接，无需公网暴露
- **Webhook**：HTTP 回调，需 3 秒内响应

### 配置

```json
{
  "channels": {
    "feishu": {
      "accounts": {
        "default": {
          "appId": "cli_xxx",
          "appSecret": "xxx",
          "domain": "feishu"
        }
      },
      "tools": {
        "doc": true,
        "wiki": true,
        "drive": true,
        "perm": false,
        "scopes": true
      }
    }
  }
}
```

### 两种知识库方案对比

| 维度 | 飞书插件（实时 API） | 内置 Memory（向量 RAG） |
|------|---------------------|------------------------|
| 数据来源 | 飞书云端文档 | 本地 .md 文件 |
| 检索方式 | Agent 主动导航/浏览 | 语义相似度 + BM25 |
| 实时性 | 实时最新 | 需同步/重建索引 |
| 适合场景 | 文档量可控、需最新内容 | 大量文档、模糊语义查询 |
| 局限 | 无全文搜索，依赖逐级导航 | 仅支持 Markdown |

### 潜在优化方向

可结合两种方案：飞书插件拉取文档 → 灌入 Memory 向量系统 → 实现语义检索 + 精读的两阶段方案。

### 关键文件

| 功能 | 文件 |
|------|------|
| 插件入口 | `extensions/feishu/index.ts` |
| 消息通道 | `extensions/feishu/src/channel.ts` |
| Bot 逻辑 | `extensions/feishu/src/bot.ts` |
| 客户端认证 | `extensions/feishu/src/client.ts` |
| 连接监控 | `extensions/feishu/src/monitor.ts` |
| 回复调度 | `extensions/feishu/src/reply-dispatcher.ts` |
| 配置 Schema | `extensions/feishu/src/config-schema.ts` |
| 飞书文档 | `docs/channels/feishu.md` |
| 中文文档 | `docs/zh-CN/channels/feishu.md` |
