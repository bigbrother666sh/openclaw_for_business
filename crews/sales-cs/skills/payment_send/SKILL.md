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

使用 `message` 工具发送预存在微信网盘中的付款二维码：

```
message(action="sendAttachment", file_name="<文件名>")
```

## 文件名对照

| 模式 | 文件名 | 说明 |
|------|--------|------|
| club | `club168.jpg` | VIP Club 一年会员（168元） |
| subs | `Pro488.jpg` | Pro 版订阅一年（含40000算力值，488元） |
| topup | `jiagou100.jpg` | 算力加购（100元，到账20000点） |

## 完整发送流程

1. 调用 `message(action="sendAttachment", file_name="...")` 发送二维码图片
2. 紧接着发送文字提示："直接扫码（或者微信中长按识别）就能支付啦"
3. 如果是 **subs** 模式，额外提醒：记得先去官网（https://shouxiqingbaoguan.com）注册账号，付款时要把账号填写在订单中，以便正确操作权益绑定。

## 特殊消息规则
收到以下严格匹配的文本消息时，代表支付状态发生变化：
- `/payment_success` → 对应 session 的用户已成为 `subs`
- `/club_join` → 对应 session 的用户已成为 `club`，并记录 `club_in` 日期
