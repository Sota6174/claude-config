#!/usr/bin/env bash
# Notification/Stop hook: cross-platform desktop notification wrapper.
# usage: notify.sh "<title>" "<message>"
#
# OS 差分はこのスクリプト内の uname 分岐に集約する（settings.json は OS 非依存に保つ）。
#   macOS            : osascript
#   Windows(Git Bash): notify.ps1 を PowerShell でバルーン表示（detached で即 return）
#   Linux / WSL2     : notify-send（あれば）
# いずれの通知手段も無い環境では黙って no-op する。
title="${1:-Claude Code}"
message="${2:-通知}"

case "$(uname -s)" in
  Darwin)
    osascript -e "display notification \"$message\" with title \"$title\"" >/dev/null 2>&1
    ;;
  MINGW*|MSYS*|CYGWIN*)
    command -v powershell.exe >/dev/null 2>&1 || exit 0
    command -v cygpath >/dev/null 2>&1 || exit 0
    ps1_win="$(cygpath -w "$HOME/.claude/hooks/notify.ps1" 2>/dev/null)"
    [ -z "$ps1_win" ] && exit 0
    # detached (nohup &) で起動し、hook は即座に return しつつバルーンは数秒残す。
    nohup powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden \
      -File "$ps1_win" -Title "$title" -Message "$message" >/dev/null 2>&1 &
    disown 2>/dev/null || true
    ;;
  Linux)
    command -v notify-send >/dev/null 2>&1 && notify-send "$title" "$message"
    ;;
esac
exit 0
