# OpenClaw for Business - Claude Code 项目规则

## 项目概述

企业级 OpenClaw 扩展项目，基于上游 openclaw/openclaw 构建。通过环境变量、补丁和插件机制在不修改上游代码的前提下实现企业定制。

## 项目结构

```
openclaw_for_business/
├── openclaw/              # 上游仓库（git submodule，禁止直接修改）
├── config-templates/      # 配置模板（版本控制）
│   └── openclaw.json     # 默认配置模板
├── patches/               # 对上游的业务补丁（.patch 文件）
├── extensions/            # 业务扩展插件
├── scripts/              # 工具脚本
│   ├── dev.sh            # 开发模式启动（前台运行）
│   ├── reinstall-daemon.sh  # 生产模式安装后台服务
│   ├── generate-patch.sh    # 生成补丁
│   ├── apply-patches.sh     # 应用补丁
│   ├── update-upstream.sh   # 更新上游代码
│   └── setup-wsl2.sh       # WSL2 环境配置
└── docs/                 # 项目文档
```

运行时数据使用上游默认位置 `~/.openclaw/`。

## 核心规则

### 1. 代码优先验证（最重要）

用户对 npm/node/pnpm 等技术栈不熟悉，可能提出不合理的要求。

- 执行任何修改前，必须先读取并理解相关代码
- 如果用户理解有误，先纠正并解释，再讨论方案
- 确认无误后才执行修改

### 2. config-templates 是最佳实践基准

`config-templates/openclaw.json` 是本项目的核心产出之一，目标是让其他用户能开箱即用。

- 每当实际运行配置（`~/.openclaw/openclaw.json`）经过验证可正常工作后，**必须将结构和最佳实践同步回 config-templates**
- 敏感信息（apiKey、appSecret、auth token 等）在模板中留空，但字段结构必须保留
- 模板应始终反映当前已验证的最佳配置结构，不得落后于实际运行配置

### 3. 禁止操作

- **禁止直接修改 `openclaw/` 目录** - 对上游的修改必须通过 `scripts/generate-patch.sh` 生成补丁到 `patches/`
- **禁止在不理解的情况下删除代码**

### 3. 修改上游代码的正确流程

```bash
cd openclaw
# 修改代码...
cd ..
./scripts/generate-patch.sh "补丁描述"
# 补丁生成到 patches/ 目录
```

### 4. 数据存储

运行时数据使用上游默认位置 `~/.openclaw/`，不做路径覆盖：
- 配置文件：`~/.openclaw/openclaw.json`
- 凭证：`~/.openclaw/credentials/`
- 工作区：`~/.openclaw/workspace/`

## 常用命令

```bash
# 开发模式（前台，实时编译）
./scripts/dev.sh gateway

# 开发模式指定端口
./scripts/dev.sh gateway --port 18789

# CLI 操作
./scripts/dev.sh cli config

# 生产部署（后台服务）
cd openclaw && pnpm build && cd ..
./scripts/reinstall-daemon.sh

# 补丁管理
./scripts/generate-patch.sh "描述"
./scripts/apply-patches.sh

# 更新上游
./scripts/update-upstream.sh
```

## 技术栈

- 运行时：Node.js + pnpm
- 上游项目：TypeScript
- 脚本：Bash
- 默认端口：18789
- 支持平台：macOS (LaunchAgent)、Linux (systemd)、WSL2

## 沟通语言

用户使用中文沟通，回复请使用中文。
