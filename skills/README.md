全局共享技能目录

放在这里的 skill 会安装到 openclaw/skills/。
是否对某个 Agent 生效，还取决于该 Agent 的 `agents.list[].skills` 白名单配置。
每个 skill 是一个子目录，包含 SKILL.md 文件。

Agent 专属的 skill 应放在 crews/<template-id>/skills/ 中。

## 内置 clawhub skills

以下 skill 不存放在本仓库，而是由 apply-addons.sh 在每次部署时从 clawhub.ai 自动拉取安装：

- `self-improving` (https://clawhub.ai/ivangdavila/self-improving)

如需增减内置 clawhub skill，修改 apply-addons.sh 中的 `CLAWHUB_SKILLS` 数组即可。
