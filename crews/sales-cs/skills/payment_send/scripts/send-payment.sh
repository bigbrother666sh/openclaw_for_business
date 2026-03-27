#!/bin/bash
# Output customer-facing payment instructions as file (QR code image) + text.
set -euo pipefail

FILE_NAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    --file-name)
      FILE_NAME="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$FILE_NAME" ]; then
  echo "Usage: $0 --file-name <club168.jpg|Pro488.jpg|jiagou100.jpg>" >&2
  exit 1
fi

# Determine mode from file name
case "$FILE_NAME" in
  club168.jpg)
    MODE="club"
    ;;
  Pro488.jpg)
    MODE="subs"
    ;;
  jiagou100.jpg)
    MODE="topup"
    ;;
  *)
    echo "❌ Unknown file name: $FILE_NAME (should be club168.jpg, Pro488.jpg, or jiagou100.jpg)" >&2
    exit 1
    ;;
esac

# JSON escape function
json_escape() {
  python3 - <<'PY' "$1"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
}

file_name_json="$(json_escape "$FILE_NAME")"

# Send image first
printf '[SEND_FILE]{"file_id":%s,"file_name":%s}[/SEND_FILE]\n' "$file_name_json" "$file_name_json"
# Then send the text message
printf '直接扫码（或者微信中长按识别）就能支付啦👆\n'

# For subs, add extra reminder
if [ "$MODE" = "subs" ]; then
  printf '\n💡记得先去我们官网（https://shouxiqingbaoguan.com）注册账号，付款时要把账号填写在订单中，以便我们能够正确操作权益绑定。\n'
fi
