#!/usr/bin/env bash
# SessionStart hook: 新規プロジェクト着手時に security-guidance プラグインの
# 取り扱いを Claude にプロンプトとして注入する。mac/Linux 用。Windows 側は同名 .ps1 で対応。
#
# 動作:
#   - source=startup の時だけ判定（resume/clear/compact は対象外）
#   - cwd/.claude/settings.json か cwd/.claude/settings.local.json が
#     あれば「既知プロジェクト」とみなして何もしない（親階層も浅く探索）
#   - cwd が $HOME と同じなら何もしない（グローバル設定で動いてる）
#   - 上記いずれにも該当しなければ additionalContext を返す
#
# 日本語の本文は new-project-security-prompt.context.txt から読み込む（.ps1 と共通）

set -e

# Windows なら .ps1 側で処理するのでスキップ
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) exit 0 ;;
esac

export PYTHONIOENCODING=utf-8

INPUT=$(cat)

parse_json() {
  python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('$1',''))" <<< "$INPUT" 2>/dev/null \
    || python -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('$1',''))" <<< "$INPUT" 2>/dev/null \
    || echo ""
}

CWD=$(parse_json cwd)
SOURCE=$(parse_json source)

[ "$SOURCE" != "startup" ] && exit 0
[ -z "$CWD" ] && exit 0

if [ "$CWD" = "$HOME" ]; then
  exit 0
fi

DIR="$CWD"
while [ -n "$DIR" ] && [ "$DIR" != "/" ] && [ "$DIR" != "$HOME" ]; do
  if [ -f "$DIR/.claude/settings.json" ] || [ -f "$DIR/.claude/settings.local.json" ]; then
    exit 0
  fi
  PARENT=$(dirname "$DIR")
  [ "$PARENT" = "$DIR" ] && break
  DIR="$PARENT"
done

# スクリプト自身の置き場所から context ファイルを解決
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTEXT_FILE="$SCRIPT_DIR/new-project-security-prompt.context.txt"
[ -f "$CONTEXT_FILE" ] || exit 0

CONTEXT_FILE="$CONTEXT_FILE" python3 - <<'PYEOF' 2>/dev/null || CONTEXT_FILE="$CONTEXT_FILE" python - <<'PYEOF'
import json, os
with open(os.environ['CONTEXT_FILE'], encoding='utf-8') as f:
    context = f.read()
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": context
    }
}, ensure_ascii=False))
PYEOF
