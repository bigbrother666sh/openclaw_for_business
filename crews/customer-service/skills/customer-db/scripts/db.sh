#!/bin/bash
# crews/customer-service/skills/customer-db/scripts/db.sh
#
# SQLite 封装脚本 — 仅供 customer-service crew 使用
# 数据库固定存放在工作区的 db/customer.db，不接受外部路径参数。
#
# 用法（从 workspace 根目录执行）:
#   db.sh init                     从 db/schema.sql 初始化数据库
#   db.sh tables                   列出所有表
#   db.sh describe <table>         显示指定表的 CREATE 语句
#   db.sh schema                   显示完整 schema（所有表）
#   db.sh sql "<SQL>"              执行受限 SQL（仅 SELECT/INSERT/UPDATE/DELETE）
set -euo pipefail

# ── 固定路径（相对于 workspace 根目录）──────────────────────────────
DB_DIR="./db"
DB_FILE="$DB_DIR/customer.db"
SCHEMA_FILE="$DB_DIR/schema.sql"

# ── 工具检查 ─────────────────────────────────────────────────────────
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "❌ sqlite3 not found. Install with: apt-get install sqlite3" >&2
  exit 1
fi

# ── 帮助 ─────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $0 <command> [args]

Commands:
  init                Initialize DB from db/schema.sql
  tables              List all tables
  describe <table>    Show CREATE statement for a table
  schema              Show full schema (all tables)
  sql "<SQL>"         Execute SQL (SELECT/INSERT/UPDATE/DELETE only)
EOF
  exit 1
}

[ $# -lt 1 ] && usage
CMD="$1"
shift

# ── SQL 安全校验 ──────────────────────────────────────────────────────
# 只允许 DML：SELECT / INSERT / UPDATE / DELETE（含 OR REPLACE 等变体）
# 拒绝 DDL 及危险操作：CREATE / DROP / ALTER / ATTACH / PRAGMA（写模式）等
validate_sql() {
  local sql="$1"
  # 去除首尾空格并转为大写首词
  local first_word
  first_word="$(printf '%s' "$sql" | sed 's/^[[:space:]]*//' | awk '{print toupper($1)}')"

  case "$first_word" in
    SELECT|INSERT|UPDATE|DELETE|WITH|EXPLAIN)
      # WITH 用于 CTE，EXPLAIN 只读
      ;;
    *)
      echo "❌ Forbidden SQL operation: $first_word" >&2
      echo "   Only SELECT, INSERT, UPDATE, DELETE are allowed." >&2
      echo "   To change schema, contact HRBP for a formal upgrade." >&2
      exit 1
      ;;
  esac

  # 二次检查：阻断内嵌的 DDL（例如在 WITH 子句后接 CREATE）
  local upper_sql
  upper_sql="$(printf '%s' "$sql" | tr '[:lower:]' '[:upper:]')"
  for banned in 'CREATE ' 'DROP ' 'ALTER ' 'ATTACH ' 'DETACH ' 'REINDEX' 'VACUUM' 'PRAGMA'; do
    if printf '%s' "$upper_sql" | grep -q "$banned"; then
      echo "❌ SQL contains forbidden keyword: $banned" >&2
      exit 1
    fi
  done
}

# ── 各子命令 ─────────────────────────────────────────────────────────

cmd_init() {
  if [ ! -f "$SCHEMA_FILE" ]; then
    echo "❌ Schema file not found: $SCHEMA_FILE" >&2
    echo "   HRBP should create db/schema.sql before running init." >&2
    exit 1
  fi

  mkdir -p "$DB_DIR"

  if [ -f "$DB_FILE" ]; then
    echo "⚠️  Database already exists: $DB_FILE"
    echo "   To reinitialize, remove $DB_FILE first."
    exit 0
  fi

  sqlite3 "$DB_FILE" < "$SCHEMA_FILE"
  echo "✅ Database initialized: $DB_FILE"
  echo "   Schema loaded from: $SCHEMA_FILE"
  cmd_tables_quiet
}

cmd_tables_quiet() {
  local tables
  tables="$(sqlite3 "$DB_FILE" ".tables" 2>/dev/null || true)"
  if [ -n "$tables" ]; then
    echo "   Tables: $tables"
  fi
}

cmd_tables() {
  ensure_db
  sqlite3 "$DB_FILE" ".tables"
}

cmd_describe() {
  [ $# -lt 1 ] && { echo "Usage: $0 describe <table>"; exit 1; }
  ensure_db
  local table="$1"
  # 验证表名：只允许字母数字下划线
  if ! printf '%s' "$table" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*$'; then
    echo "❌ Invalid table name: $table" >&2
    exit 1
  fi
  sqlite3 "$DB_FILE" ".schema $table"
}

cmd_schema() {
  ensure_db
  sqlite3 "$DB_FILE" ".schema"
}

cmd_sql() {
  [ $# -lt 1 ] && { echo "Usage: $0 sql \"<SQL>\""; exit 1; }
  ensure_db
  local sql="$1"
  validate_sql "$sql"
  # 输出表头（.headers on）+ tab 分隔（.mode tabs）
  sqlite3 -header -separator $'\t' "$DB_FILE" "$sql"
}

ensure_db() {
  if [ ! -f "$DB_FILE" ]; then
    echo "❌ Database not found: $DB_FILE" >&2
    echo "   Run: bash ./skills/customer-db/scripts/db.sh init" >&2
    exit 1
  fi
}

# ── 路由 ─────────────────────────────────────────────────────────────
case "$CMD" in
  init)     cmd_init ;;
  tables)   cmd_tables ;;
  describe) cmd_describe "$@" ;;
  schema)   cmd_schema ;;
  sql)      cmd_sql "$@" ;;
  *)        echo "❌ Unknown command: $CMD" >&2; usage ;;
esac
