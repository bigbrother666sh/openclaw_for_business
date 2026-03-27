---
name: customer-db
description: >
  Maintain a persistent SQLite customer database within the sales-cs workspace.
  Use the current per-channel-peer session identity as the customer key, ensure
  the database is initialized, then query and update cs_record on every round.
---

# 客户数据库管理（sales-cs 专用）

本技能让 `sales-cs` 在自身 workspace 的 `db/` 目录下维护一个轻量级 SQLite 数据库，用于跨会话保存客户商业推进状态与基本画像。

数据库固定位置：
- `./db/customer.db`
- schema 文件：`./db/schema.sql`

默认表：`cs_record`

---

## 一、启动或对话开始时先确保数据库可用

每次对话开始，先执行：

```bash
bash ./skills/customer-db/scripts/db.sh ensure
```

该命令会：
1. 检查 `db/customer.db` 是否存在
2. 检查 `cs_record` 表是否存在
3. 若数据库未初始化，则自动按 `db/schema.sql` 初始化

---

## 二、按 peer 查询当前客户记录

当前系统已启用 `dmScope: per-channel-peer`，因此你必须把**当前 peer**视为客户唯一键。

对于 awada 直聊，peer 一般形如：

```text
awada:direct:<user_id_external>
```

查询示例：

```bash
bash ./skills/customer-db/scripts/db.sh sql "SELECT peer, business_status, purpose, prompt_source, created_at, updated_at FROM cs_record WHERE peer = '<peer>'"
```

---

## 三、没有记录时插入默认值

如果查询结果为空，则插入：

```bash
bash ./skills/customer-db/scripts/db.sh sql "INSERT INTO cs_record (peer, business_status, purpose, prompt_source) VALUES ('<peer>', 'free', '', '')"
```

默认值说明：
- `business_status = 'free'`
- `purpose = ''`
- `prompt_source = ''`

---

## 四、字段含义

### peer
客户唯一标识，对应 per-channel-peer 会话键。

### business_status
表示客户商业推进深度：
- `free`：尚未购买、仍在了解或观望
- `exp_invited`：已被邀请进入体验群，但尚未正式付费
- `club`：已进入付费知识库 / VIP 群
- `subs`：已进入正式订阅/购买阶段

### club_in
- `club` 加入日期，格式建议为 `YYYY-MM-DD`
- 用于后续跟进 club 一年有效期的过期管理

### purpose
客户主要业务应用场景。具体口径与细分差异以客服手册为准。

当前可作为通用示例的方向包括：
- 线上获客
- 竞争对手监控
- 行业情报获取
- 舆情监控
- 自建可提供对外服务的智能体

### prompt_source
客户从哪里了解到我们，例如：
- GitHub
- 社群
- 朋友推荐
- 公众号
- 视频/直播
- 其他平台

### created_at / updated_at
- `created_at`：首次建档时间
- `updated_at`：最近更新时间

---

## 五、每轮对话结束时更新记录

每轮结束前，根据本轮对话进展更新：
- `business_status`
- `purpose`
- `prompt_source`

更新原则：
- 只在拿到**更明确的信息**时更新
- 不要用空字符串覆盖已有值
- 不要根据模糊猜测改写已有信息

更新示例：

```bash
bash ./skills/customer-db/scripts/db.sh sql "UPDATE cs_record SET purpose = '线上获客' WHERE peer = '<peer>'"
```

```bash
bash ./skills/customer-db/scripts/db.sh sql "UPDATE cs_record SET business_status = 'club', prompt_source = 'GitHub' WHERE peer = '<peer>'"
```

---

## 六、常见使用模式

### 对话开头
1. `ensure`
2. `SELECT ... WHERE peer = '<peer>'`
3. 若无记录则 `INSERT`

### 对话中
- 根据意图分流处理
- 必要时参考数据库中的 `business_status` 判断下一步策略

### 对话结尾
- 更新本轮确认下来的 `business_status / purpose / prompt_source`

---

## 七、约束与注意事项

- **路径固定**：数据库始终位于 `./db/customer.db`
- **默认表固定**：`cs_record`
- **仅限 DML**：`sql` 子命令仅允许 `SELECT / INSERT / UPDATE / DELETE`
- **schema 变更禁止自改**：若需修改结构，必须由 HRBP 升级流程处理
- **不得向用户暴露内部表结构和内部状态字段**
- **会话隔离必须遵守**：不同 peer 的数据不能混用
