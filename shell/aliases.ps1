# Claude Code PowerShell aliases (synced via claude-config repo)
# セットアップ手順は README.md の「シェルエイリアスの読み込み」を参照。

# Claude Code: モデル/エフォート指定で起動
function claude-o  { claude --model claude-opus-4-7 --effort high @args }
function claude-ox { claude --model claude-opus-4-7 --effort xhigh @args }
function claude-s  { claude --model sonnet --effort high @args }
