#!/usr/bin/env bash
# PostToolUse(Bash) hook: 大量出力を人間に通知し、出力を絞るコマンドを提案する nudge。
#
# 重要: Claude Code の PostToolUse hook は tool の出力(tool_response)を縮約・truncate できない。
# できるのは additionalContext の追記(=context が増える)か、systemMessage(=人間にだけ表示・
# Claude の context には入らない=0トークン)のみ。よってこの hook は出力を削る装置ではなく、
# 「次回からフィルタする」ための人間向けリマインダーに徹する。
#
# macOS(Darwin/zsh) 前提の注意:
#   - 非対話シェルでは grep が ugrep alias に解決されないため grep -P 等に依存しない。
#   - パースは jq 一本(/opt/homebrew/bin/jq)。jq 不在なら黙って no-op。
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"

printf '%s' "$input" | jq '
  (.tool_response | tostring | length) as $len
  | (.tool_input.command // "") as $cmd
  | if $len > 50000 then
      ( if   ($cmd | test("vitest|run test|playwright")) then " (次回: --reporter=dot か 2>&1 | tail -n 80 で絞れます)"
        elif ($cmd | test("git log"))                    then " (次回: git log --oneline -n 30)"
        elif ($cmd | test("^(cat|less|head|tail) "))     then " (次回: grep で該当行に絞る / Read の offset,limit)"
        else "" end ) as $hint
      | { suppressOutput: true,
          systemMessage: ("⚠️ Bash出力が大きめ: 約 \(($len/1000)|floor)k文字。次回は出力を絞ると context を節約できます" + $hint) }
    else empty end
'
exit 0
