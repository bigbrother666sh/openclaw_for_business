---
name: customer-db
description: >
  Maintain a persistent SQLite customer database within the crew workspace.
  Store and retrieve customer state, order history, preferences, and any
  domain-specific records defined by the operator at deployment time.
---

# 客户数据库管理

本技能让客服助手能够在自身 workspace 的 `db/` 目录下维护一个轻量级 SQLite 数据库，用于在跨会话中持久化客户状态、记录交互历史、或存储业务相关的结构化数据。

数据库 schema 由 HRBP 在招募（实例化）时定义，存放在 `db/schema.sql`。

---

## 一、了解你的数据库

启动后，先确认当前的表结构，以便正确使用：

```
bash ./skills/customer-db/scripts/db.sh tables
```

查看具体表的列定义：

```
bash ./skills/customer-db/scripts/db.sh describe <table_name>
```

---

## 二、查询数据

使用标准 SELECT 语句查询：

```
bash ./skills/customer-db/scripts/db.sh sql "SELECT * FROM customers WHERE phone = '138xxxx0001'"
```

```
bash ./skills/customer-db/scripts/db.sh sql "SELECT * FROM customers WHERE id = 42"
```

**注意**：
- 字符串值必须用**单引号**括起来
- `sql` 子命令仅允许 `SELECT`、`INSERT`、`UPDATE`、`DELETE`，禁止 DDL（`CREATE`/`DROP`/`ALTER` 等）
- 输出格式为表头+tab分隔值，便于解析

---

## 三、写入 / 更新数据

### INSERT（新增记录）

```
bash ./skills/customer-db/scripts/db.sh sql "INSERT INTO customers (name, phone, status) VALUES ('张三', '138xxxx0001', 'active')"
```

### UPDATE（更新记录）

```
bash ./skills/customer-db/scripts/db.sh sql "UPDATE customers SET status = 'vip' WHERE phone = '138xxxx0001'"
```

### INSERT OR REPLACE（存在则更新，不存在则插入）

```
bash ./skills/customer-db/scripts/db.sh sql "INSERT OR REPLACE INTO customers (id, name, phone, status) VALUES (42, '张三', '138xxxx0001', 'vip')"
```

### DELETE（删除记录）

```
bash ./skills/customer-db/scripts/db.sh sql "DELETE FROM customers WHERE id = 42"
```

---

## 四、使用场景示例

### 识别回头客

对话开始时，根据用户渠道标识查询数据库：

```
bash ./skills/customer-db/scripts/db.sh sql "SELECT * FROM customers WHERE channel_id = '<用户ID>'"
```

- 有记录 → 展示历史背景，个性化问候
- 无记录 → 初次服务，对话结束后可视情况入库

### 记录客户状态变化

用户完成购买、升级、或特殊处理后更新状态：

```
bash ./skills/customer-db/scripts/db.sh sql "UPDATE customers SET status = 'vip', last_purchase = date('now') WHERE channel_id = '<用户ID>'"
```

### 查询历史工单

```
bash ./skills/customer-db/scripts/db.sh sql "SELECT * FROM tickets WHERE customer_id = 42 ORDER BY created_at DESC LIMIT 5"
```

---

## 五、约束与注意事项

- **路径固定**：数据库始终位于 `./db/customer.db`（workspace 根目录下），不可修改路径
- **仅限 DML**：禁止执行 DDL 语句（CREATE/DROP/ALTER/PRAGMA 修改类）；schema 变更需联系 HRBP
- **会话隔离**：`dmScope: per-channel-peer` 确保每个客户会话独立，但数据库本身跨会话持久存储
- **数据安全**：不得将数据库中的内部 ID、敏感字段直接回显给用户
- **schema 来源**：`db/schema.sql` 由 HRBP 在招募时写入，反映了当前业务的数据模型；若需修改 schema，由 HRBP 通过升级流程处理
