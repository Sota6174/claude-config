#!/usr/bin/env bash
# Notification/Stop hook: desktop notification wrapper for mac/Linux.
# usage: notify.sh "<title>" "<message>"
#
# Windows 側は同名 .ps1 で対応するため、ここでは mac/Linux のみ扱う。
#   macOS        : osascript
#   Linux / WSL2 : notify-send（あれば）
# いずれも無い環境では黙って no-op する。
title="${1:-Claude Code}"
message="${2:-通知}"

case "$(uname -s)" in
  Darwin)
    osascript -e "display notification \"$message\" with title \"$title\"" >/dev/null 2>&1
    ;;
  Linux)
    command -v notify-send >/dev/null 2>&1 && notify-send "$title" "$message"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    # Windows は notify.ps1 を直接 hook から呼び出す。ここでは何もしない。
    :
    ;;
esac
exit 0
