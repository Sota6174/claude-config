#!/usr/bin/env bash
# Claude Code statusline: stdin の JSON を 2 行で出力する (ローカル実行・API トークン非消費)
# 1 行目: [モデル] ⚡effort · 📁プロジェクト · 🌿ブランチ
# 2 行目: ⏳5h [bar] % Xh Ym │ 📅7d % │ 🧠ctx [bar] %  (5h 末尾はリセットまでの残り時間)
set -o pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "[statusline] jq not found"
  exit 0
fi

input=$(cat)
jqr() { jq -r "$1" 2>/dev/null <<<"$input"; }

MODEL=$(jqr '.model.display_name // "?"')
EFFORT=$(jqr '.effort.level // empty')
DIR=$(jqr '.workspace.current_dir // .cwd // "."')
PROJECT_DIR=$(jqr '.workspace.project_dir // empty')
PROJECT=$(basename "${PROJECT_DIR:-$DIR}")
FIVE=$(jqr '.rate_limits.five_hour.used_percentage // empty')
RESET5=$(jqr '.rate_limits.five_hour.resets_at // empty')
WEEK=$(jqr '.rate_limits.seven_day.used_percentage // empty')
CTX=$(jqr '.context_window.used_percentage // empty')

G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; M=$'\033[35m'; DIM=$'\033[2m'; X=$'\033[0m'

round() { printf '%.0f' "${1:-0}" 2>/dev/null || echo 0; }

color_for() {
  local v=${1%.*}; v=${v:-0}
  if   [ "$v" -ge "$3" ]; then printf '%s' "$R"
  elif [ "$v" -ge "$2" ]; then printf '%s' "$Y"
  else printf '%s' "$G"; fi
}

bar() {
  local pct=${1%.*}; pct=${pct:-0}; local w=${2:-8}
  local filled=$(( pct * w / 100 )); [ "$filled" -gt "$w" ] && filled=$w
  [ "$filled" -lt 0 ] && filled=0
  local empty=$(( w - filled )) f e
  printf -v f '%*s' "$filled" ''
  printf -v e '%*s' "$empty" ''
  printf '%s%s' "${f// /▓}" "${e// /░}"
}

remaining_str() {
  local s=${1:-0}; [ "$s" -lt 0 ] && s=0
  local h=$(( s / 3600 )) m=$(( (s % 3600) / 60 ))
  if   [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then printf '%dm' "$m"
  else printf '<1m'; fi
}

BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
line1="${C}[$MODEL]${X}"
[ -n "$EFFORT" ] && line1="$line1 ${M}⚡$EFFORT${X}"
[ -n "$PROJECT" ] && line1="$line1 ${DIM}·${X} 📁 ${C}$PROJECT${X}"
[ -n "$BRANCH" ] && line1="$line1 ${DIM}·${X} 🌿 $BRANCH"
printf '%s\n' "$line1"

parts=()
if [ -n "$FIVE" ] || [ -n "$WEEK" ]; then
  if [ -n "$FIVE" ]; then
    p=$(round "$FIVE"); col=$(color_for "$p" 60 85)
    five="⏳5h ${col}$(bar "$p" 8) ${p}%${X}"
    if [ -n "$RESET5" ]; then
      remain=$(( RESET5 - $(date +%s) ))
      five="$five $(remaining_str "$remain")"
    fi
    parts+=("$five")
  fi
  if [ -n "$WEEK" ]; then
    p=$(round "$WEEK"); col=$(color_for "$p" 60 85)
    parts+=("📅7d ${col}${p}%${X}")
  fi
else
  parts+=("${DIM}rate-limit: n/a${X}")
fi
if [ -n "$CTX" ]; then
  p=$(round "$CTX"); col=$(color_for "$p" 70 90)
  parts+=("🧠ctx ${col}$(bar "$p" 8) ${p}%${X}")
fi

sep=" ${DIM}│${X} "
out=""
for i in "${!parts[@]}"; do
  [ "$i" -gt 0 ] && out="$out$sep"
  out="$out${parts[$i]}"
done
printf '%s\n' "$out"
