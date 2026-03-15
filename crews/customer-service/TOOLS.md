# Customer Service — Tools

## Available Tools

**Only declared skills are available** (see `DECLARED_SKILLS`). No shell execution is available (T0), with one precise exception: `db.sh` (see Customer Database below).

- `nano-pdf`: Read PDF documents from knowledge base
- `xurl`: Fetch web content for information lookup
- `mcporter`: Call Alipay MCP Server for payment operations
- `customer-db`: Persistent SQLite database for customer records (see below)
- File write: Record feedback to `feedback/YYYY-MM-DD.md` (append mode)

## Tool Usage Rules

### Knowledge Base Access
- Use `nano-pdf` to read product documentation, policy documents, FAQs
- Use `xurl` to fetch public web content for factual queries
- Do NOT use these tools to modify any files other than the feedback directory

### Alipay Payment via mcporter

The Alipay MCP Server is pre-configured as `alipay` in mcporter. Available tools:

| Tool | 用途 | 调用方式 |
|------|------|----------|
| `create-mobile-alipay-payment` | 创建手机支付订单，返回支付链接 | `mcporter call alipay.create-mobile-alipay-payment outTradeNo=<订单号> totalAmount=<金额> orderTitle=<标题>` |
| `create-web-page-alipay-payment` | 创建网页支付订单（PC扫码/登录） | `mcporter call alipay.create-web-page-alipay-payment outTradeNo=<订单号> totalAmount=<金额> orderTitle=<标题>` |
| `query-alipay-payment` | 查询支付状态 | `mcporter call alipay.query-alipay-payment outTradeNo=<订单号>` |
| `refund-alipay-payment` | 发起退款 | `mcporter call alipay.refund-alipay-payment outTradeNo=<订单号> refundAmount=<退款金额> outRequestNo=<退款请求号>` |
| `query-alipay-refund` | 查询退款状态 | `mcporter call alipay.query-alipay-refund outRequestNo=<退款请求号> outTradeNo=<订单号>` |

**支付操作注意事项**：
- `outTradeNo` 必须是真实商户订单系统中的订单号（最长64字符）
- `totalAmount` 单位为元，最小 0.01
- `outRequestNo` 退款请求号须唯一，可用 `<outTradeNo>-refund-<时间戳>` 格式
- 所有 L3 支付操作（退款/大额支付）须在执行前向用户明确确认
- 退款操作不可逆，务必核实订单信息后再执行

### Customer Database via customer-db

持久化客户数据，跨会话保存状态。数据库文件位于 `db/customer.db`，schema 由 HRBP 在部署时定义。

**调用方式**（通过 `ALLOWED_COMMANDS` 放行的精确白名单）：

```
bash ./skills/customer-db/scripts/db.sh <subcommand>
```

| 子命令 | 用途 | 示例 |
|--------|------|------|
| `tables` | 列出所有表 | `db.sh tables` |
| `describe <table>` | 查看表结构 | `db.sh describe customers` |
| `schema` | 显示完整 schema | `db.sh schema` |
| `sql "<SQL>"` | 执行 DML | `db.sh sql "SELECT * FROM customers WHERE phone='138x'"` |

**约束**：
- 仅允许 `SELECT / INSERT / UPDATE / DELETE`，DDL 语句会被拒绝
- 不得暴露数据库内部字段（ID、内部状态码）给用户
- schema 变更须联系 HRBP 通过升级流程处理，不得自行修改

### Feedback Recording
- Feedback file path: `feedback/YYYY-MM-DD.md` (relative to this workspace)
- Always append to the file, never overwrite
- Follow the feedback entry template from `shared/CREW_TYPES.md`
- Record **after** completing customer interaction, **before** session ends

### Restrictions
- No arbitrary shell command execution (T0 security level)
- The only permitted shell command is `./skills/customer-db/scripts/db.sh` (via ALLOWED_COMMANDS)
- No file writes outside `feedback/` and `db/` directories
- No self-modification of workspace files (SOUL.md, AGENTS.md, MEMORY.md, etc.)
- mcporter 仅用于调用预配置的 `alipay` MCP Server，不得配置或调用其他服务

