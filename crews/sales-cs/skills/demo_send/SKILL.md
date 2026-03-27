---
name: demo_send
description: >
  Send product demo material to a free-status customer when they
  ask about concrete usage, want to understand the product form, or need a
  first visual reference before deeper sales qualification.
---

# demo_send

## 用途
当客户属于 `free` 状态，且提出具体使用问题、想先看看产品形态、或需要一个直观参考时，发送 demo 材料。

## 调用方式

```bash
bash ./skills/demo_send/scripts/send-demo.sh --file-name "<文件名>" --follow-up "<追问文本>"
```

可选参数：
- `--intro "<介绍文字>"` 自定义介绍语（默认："我先发您一份 demo 视频供参考。"）
- `--follow-up "<追问文本>"` 发送后追问客户需求

**示例**：
```bash
bash ./skills/demo_send/scripts/send-demo.sh --file-name "wiseflow_pro_4.x_demo.mp4" --follow-up "您这边更想把它用在获客、行业情报，还是做一个能对外服务的智能体？"
```

## 输出格式

脚本输出包含：
1. 介绍文字
2. `[SEND_FILE]` 标签触发文件发送
3. 追问文字（如有）
4. 官网/GitHub 提醒

**输出示例**：
```
我先发您一份 demo 视频供参考。
[SEND_FILE]{"file_id":"wiseflow_pro_4.x_demo.mp4","file_name":"wiseflow_pro_4.x_demo.mp4"}[/SEND_FILE]
您这边更想把它用在获客、行业情报，还是做一个能对外服务的智能体？
建议您也去我们官网以及 GitHub 主页获取最新产品信息。
```

## 调用后必须做的事
发送 demo 后，**必须立刻追问客户的具体需求或应用场景**，不得只发完就结束。

## ⚠️ 输出规则（必须遵守）
- 执行脚本后，**直接将脚本输出作为最终回复发送给客户**，不要重新改写、重述或总结。
- 产出含 `[SEND_FILE]...[/SEND_FILE]` 的文本后，必须直接作为最终回复输出；

严禁再调用 `message` 工具转发该文本。
