#!/bin/bash
# Output an awada SEND_FILE reply for demo delivery.
# Simplified: only FILE_NAME is required.
set -euo pipefail

FILE_NAME=""
FOLLOW_UP=""
INTRO="我先发您一份 demo 视频供参考。"
REMINDER="建议您也去我们官网以及 GitHub 主页获取最新产品信息。"

while [ $# -gt 0 ]; do
  case "$1" in
    --file-name)
      FILE_NAME="${2:-}"
      shift 2
      ;;
    --follow-up)
      FOLLOW_UP="${2:-}"
      shift 2
      ;;
    --intro)
      INTRO="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$FILE_NAME" ]; then
  echo "Usage: $0 --file-name <file_name> [--follow-up <text>] [--intro <text>]" >&2
  exit 1
fi

json_escape() {
  python3 - <<'PY' "$1"
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
}

file_name_json="$(json_escape "$FILE_NAME")"

printf '%s\n' "$INTRO"
printf '[SEND_FILE]{"file_id":%s,"file_name":%s}[/SEND_FILE]\n' "$file_name_json" "$file_name_json"
if [ -n "$FOLLOW_UP" ]; then
  printf '%s\n' "$FOLLOW_UP"
fi
printf '%s\n' "$REMINDER"
