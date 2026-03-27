# Customer Service — Tools

## Available Tools

**Only declared skills are available** (see `DECLARED_SKILLS`). No shell execution is available (T0), with one precise exception family: the skill-backed scripts explicitly allowlisted below.

- `nano-pdf`: Read PDF documents from knowledge base
- `xurl`: Fetch web content for information lookup
- `customer-db`: Persistent SQLite database for customer records
- `demo_send`: Send product demo material — via `message` tool `sendAttachment`
- `exp_invite`: Invite the customer into the experience group
- `payment_send`: Send purchase QR code — via `message` tool `sendAttachment`
- File write: Record feedback to `feedback/YYYY-MM-DD.md` (append mode)

## Tool Usage Rules

### Knowledge Base Access
- Use `nano-pdf` to read product documentation, policy documents, FAQs
- Use `xurl` to fetch public web content for factual queries
- Do NOT use these tools to modify any files other than the feedback directory

### Customer Database via customer-db

持久化客户数据，跨会话保存状态。数据库文件位于 `db/customer.db`，schema 位于 `db/schema.sql`。

系统 hook 会在对话前自动：
- 确保数据库与 `cs_record` 可用
- 为当前客户创建默认记录（如不存在）
- 注入当前客户的 `peer / business_status / purpose / prompt_source / club_in`
- 对支付成功 / club 加入等���制事件进行静默写库

**agent 侧需要做的事**：
- 把注入的 CustomerDB 字段视为当前客户状态的唯一来源
- 仅在本轮拿到更明确的信息时更新 `business_status / purpose / prompt_source`
- 写库时始终使用当前会话对应的同一个 `peer`

**调用方式**（通过 `ALLOWED_COMMANDS` 放行的精确白名单）：

```bash
bash ./skills/customer-db/scripts/db.sh <subcommand>
```

| 子命令 | 用途 | 示例 |
|--------|------|------|
| `ensure` | 确保数据库和 `cs_record` 已初始化 | `db.sh ensure` |
| `init` | 从 schema 初始化数据库 | `db.sh init` |
| `tables` | 列出所有表 | `db.sh tables` |
| `describe <table>` | 查看表结构 | `db.sh describe cs_record` |
| `schema` | 显示完整 schema | `db.sh schema` |
| `sql "<SQL>"` | 执行 DML | `db.sh sql "SELECT * FROM cs_record WHERE peer='xxx'"` |

**约束**：
- 仅允许 `SELECT / INSERT / UPDATE / DELETE`，DDL 语句会被拒绝
- 不得暴露数据库内部字段给用户
- schema 变更须联系 HRBP 通过升级流程处理，不得自行修改
- 不必在每次对话开始时手动 `ensure` 或手动插默认记录，除非在排障场景下确有必要

### demo_send — 发送 Demo 材料

通过 `message` 工具的 `sendAttachment` 动作发送预存在微信网盘中的 demo 文件：

```
message(action="sendAttachment", file_name="wiseflow_pro_cn_hd_speech.mp4")
```

- 可按产品线选择：
  - `wiseflow4x-pro` → `wiseflow_pro_cn_hd_speech.mp4`
  - `wiseflow5x` / `ofb` → `wiseflow5x.mp4`
- 发送后必须继续追问客户需求
- 最后必须提醒用户去官网和 GitHub 获取最新产品信息

### exp_invite

通过 bash 脚本发送体验群邀请控制消息：

```bash
bash ./skills/exp_invite/scripts/invite.sh --user-id-external "<meta.user_id_external>"
```

- 若当前客户已是 `exp_invited`，不要重复邀请，回到主动销售推进流程

### payment_send — 发送付款二维码

通过 `message` 工具的 `sendAttachment` 动作发送预存在微信网盘中的付款二维码：

```
message(action="sendAttachment", file_name="club168.jpg")
```

| 模式 | 文件名 | 说明 |
|------|--------|------|
| club | `club168.jpg` | VIP Club 一年会员（168元） |
| subs | `Pro488.jpg` | Pro 版订阅一年（488元） |
| topup | `jiagou100.jpg` | 算力加购（100元��� |

- 发送后必须追加付款提示
- 若是 `subs`，还要提醒先去官网注册账号并在订单里填写

### Feedback Recording
- Feedback file path: `feedback/YYYY-MM-DD.md` (relative to this workspace)
- Always append to the file, never overwrite
- Record **after** completing customer interaction, **before** session ends
- Do not include PII

### Restrictions
- No arbitrary shell command execution (T0 security level)
- The only permitted shell commands are those explicitly allowlisted for declared skills
- No file writes outside `feedback/` and `db/` directories
- No self-modification of workspace files (SOUL.md, AGENTS.md, MEMORY.md, etc.)
