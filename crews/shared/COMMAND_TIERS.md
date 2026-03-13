# 命令白名单分层规范（Command Allowlist Tiers）

> 本文件定义 OFB 各 Crew 的 shell 命令执行权限层级。
> 更新日期：2026-03-10

---

## 层级概览

| Tier | 名称 | 描述 | 适用 Crew |
|------|------|------|-----------|
| T0 | read-only | 无 shell 执行权限，只读文件内容 | customer-service, content-writer, market-analyst |
| T1 | basic-shell | 只读型系统命令，无破坏性 | main, operations |
| T2 | dev-tools | 开发工具链，有限文件系统操作 | developer, hrbp |
| T3 | admin | 完整系统操作���含 OFB 维护脚本 | it-engineer |

---

## T0 — read-only

**无 shell 命令执��权限。**

允许：
- 读取文件（通过 Claude 内置文件工具）
- 不通过 shell 执行任何命令

禁止：
- 任何 Bash / shell 命令

---

## T1 — basic-shell

**只读型系统命令，不修改文件系统或系统状态。**

允许的命令：
```
cat          # 读取文件内容
ls           # 列出目录
grep         # 搜索文本
find         # 查找文件（只读）
ps           # 查看进程状态
date         # 查看当前时间
echo         # 输出文本
pwd          # 当前目录
env          # 查看环境变量
which        # 查找命令路径
head         # 读取文件头部
tail         # 读取文件尾部（含 tail -f 日志跟踪）
wc           # 统计行数/字数
sort         # 排序
uniq         # 去重
diff         # 比较文件差异
curl -s      # 只读 HTTP 请求（GET，禁止 POST 携带敏感数据）
```

禁止：
- `rm`, `mv`, `cp`, `mkdir`, `chmod`, `chown`
- 写入文件的重定向（`>`, `>>`）
- 管道到写入命令
- `sudo`, `su`
- 任何服务管理命令（`systemctl`, `pm2`, etc.）

---

## T2 — dev-tools

**开发工具链，允许有限文件系统操作。**

包含 T1 所有命令，额外允许：
```
git          # 版本控制（所有子命令，但不含 git push --force）
npm          # Node 包管��
pnpm         # Node 包管理
bun          # JS 运行时
node         # Node.js 执行
python / python3  # Python 执行
pip / pip3   # Python 包管理
cp           # 复制文件
mv           # 移动/重命名文件
mkdir        # 创建目录
rm           # 删除文件（禁止 rm -rf /，禁止删除系统目录）
touch        # 创建空文件
chmod        # 修改文件权限（仅用户目录下）
```

禁止：
- `sudo`, `su`
- `pm2`（服务管理）
- 任何 OFB 维护脚本（`setup-crew.sh`, `reinstall-daemon.sh`, `upgrade.sh`）
- `rm -rf` 作用于 `~/.openclaw/` 或系统目录
- `git push --force`

---

## T3 — admin

**完整系统操作，含 OFB 所有维护脚本。**

包含 T2 所有命令，额外允许：
```
pm2          # 进程管理（list, logs, restart, stop, start, delete）
systemctl    # 系统服务管理
bash         # 执行 shell 脚本
sh           # 执行 shell 脚本

# OFB 专属维护脚本（需 cd 到 OFB 项目目录）
./scripts/dev.sh
./scripts/reinstall-daemon.sh
./scripts/setup-crew.sh
./scripts/apply-addons.sh
./scripts/upgrade.sh
```

仍然禁止（即使 T3 也不允许）：
- `rm -rf /`（根目录删除）
- `rm -rf ~/`（用户目录全删）
- 修改 `/etc/` 下的系统关键配置（除非明确运维需求）
- 执行来自网络的未验证脚本（`curl | bash`）

---

## 声明方式

每个 Crew 在其 `SOUL.md` 的 `## 权限级别` 章节中声明：

```markdown
## 权限级别
command-tier: T2
```

如需在 Tier 基础上做额外调整，在模板目录创建 `ALLOWED_COMMANDS` 文件：
- `+<command>` 表示在本 Tier 基础上追加允许该命令
- `-<command>` 表示在本 Tier 基础上屏蔽该命令

示例（`ALLOWED_COMMANDS`）：
```
# 在 T2 基础上额外允许 setup-crew.sh（HRBP 需要）
+./scripts/setup-crew.sh
# 屏蔽 rm（本 Crew 不需要删除文件）
-rm
```

---

## 修改记录

| 日期 | 变更 | 作者 |
|------|------|------|
| 2026-03-10 | 初始版本，定义 T0-T3 四层权限 | 用户 + Claude |
