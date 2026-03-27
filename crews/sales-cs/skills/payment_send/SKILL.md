---
name: payment_send
description: >
  Send payment QR code image to customer for purchase.
  Supports club (168), subs (488), and topup (100) modes.
---

# payment_send

## 用途
当客户表达明确购买意向时，发送付款二维码图片，推进成交。

## 调用方式

```bash
bash ./skills/payment_send/scripts/send-payment.sh --file-name club168.jpg
```

或：

```bash
bash ./skills/payment_send/scripts/send-payment.sh --file-name Pro488.jpg
```

或（Pro 订阅用户加购算力时）：

```bash
bash ./skills/payment_send/scripts/send-payment.sh --file-name jiagou100.jpg
```

## 文件名对照

| 模式 | 文件名 | 说明 |
|------|--------|------|
| club | `club168.jpg` | VIP Club 一年会员（168元） |
| subs | `Pro488.jpg` | Pro 版订阅一年（含40000算力值，488元） |
| topup | `jiagou100.jpg` | 算力加购（100元，到账20000点） |

## 输出格式

脚本输出包含：
1. `[SEND_FILE]` 标签触发图片发送
2. 提示文字："直接扫码（或者微信中长按识别）就能支付啦👆"
3. subs 模式会额外提示注册账号

**输出示例（subs）**：
```
[SEND_FILE]{"file_id":"Pro488.jpg","file_name":"Pro488.jpg"}[/SEND_FILE]
直接扫码（或者微信中长按识别）就能支付啦👆

💡记得先去我们官网（https://shouxiqingbaoguan.com）注册账号，付款时要把账号填写在订单中，以便我们能够正确操作权益绑定。
```

## ⚠️ 输出规则（必须遵守）
- 执行脚本后，**直接将脚本输出作为最终回复发送给客户**，不要重新改写、重述或总结。
- 产出含 `[SEND_FILE]...[/SEND_FILE]` 的文本后，必须直接作为最终回复输出。

## 特殊消息规则
收到以下严格匹配的文本消息时，代表支付状态发生变化：
- `/payment_success` → 对应 session 的用户已成为 `subs`
- `/club_join` → 对应 session 的用户已成为 `club`，并记录 `club_in` 日期
