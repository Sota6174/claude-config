# Claude Code shell aliases (synced via claude-config repo)
# alias 構文は bash/zsh 共通。使うシェルの rc から読み込む:
#   macOS          : echo 'source "$HOME/.claude/shell/aliases.sh"' >> ~/.zshrc
#   Linux/Git Bash : echo 'source "$HOME/.claude/shell/aliases.sh"' >> ~/.bashrc

# Claude Code: モデル/エフォート指定で起動
alias claude-o='claude --model claude-opus-4-7 --effort high'
alias claude-ox='claude --model claude-opus-4-7 --effort xhigh'
alias claude-s='claude --model sonnet --effort high'
