# Claude Code グローバル設定 (Windows)

`~/.claude` のうち **手書きの設定ファイルだけ** を git 管理して、複数端末で同期するためのリポジトリ。

`.gitignore` は allowlist 方式（まず `*` で全無視 → 設定ファイルだけ `!` で復活）。
`projects/`・`plugins/`(1.7GB)・`history.jsonl`・各種 cache/session/state などの
巨大な状態ファイルや認証情報は **意図的に追跡しない**。

## 管理対象

| ファイル | 役割 |
|---|---|
| `CLAUDE.md` | 全プロジェクト共通のグローバル規約 |
| `settings.json` | 権限・hooks・statusLine・有効プラグイン・言語など |
| `keybindings.json` | キーバインド |
| `statusline.sh` | ステータスライン生成スクリプト（Git Bash + jq で動作） |
| `.mcp.json` | グローバル MCP サーバ定義 |
| `hooks/` | カスタム hook スクリプト（PowerShell） |
| `shell/aliases.ps1` | PowerShell 用の起動エイリアス（`claude-o` / `claude-s` 等） |

> パスはすべて `~/.claude/...`（チルダ表記）。PowerShell でも `~` は `$HOME` に解決されるのでそのまま動く。

> **対象 OS:** Windows + PowerShell 専用。Mac/Linux 用の設定は別リポジトリ
> [claude-config-mac](https://github.com/Sota6174/claude-config-mac) で管理している。
> Windows ↔ Mac 方向で共通変更を取り込みたい場合は、相手側で本リポジトリを
> `remote` として追加し `git cherry-pick` で必要分だけ拾う。

## 別端末でのセットアップ

### Claude Code のインストール（重要）

**`npm install -g @anthropic-ai/claude-code` は使わない。** mise / nodenv / nvm 等でプロジェクトごとに Node バージョンを pin している環境では、そのディレクトリに入ると `claude` が見つからなくなる。

代わりに **Node 非依存のネイティブ版インストーラー** を使う:

```powershell
# PowerShell
irm https://claude.ai/install.ps1 | iex
```

```bash
# 代替: Git Bash
curl -fsSL https://claude.ai/install.sh | bash
```

---

`~/.claude` がまだ無い、または空の端末:

```bash
git clone git@github.com:Sota6174/claude-config-windows.git ~/.claude
```

`~/.claude` が既に存在する端末（Claude Code 使用済み）は、ディレクトリを消さずに
リポジトリだけ後付けする:

```bash
cd ~/.claude
git init
git remote add origin git@github.com:Sota6174/claude-config-windows.git
git fetch origin
git checkout -t origin/main -f   # 追跡対象の設定ファイルだけ上書きされる（状態ファイルは無傷）
```

### 依存ツール

- **Git for Windows (Git Bash)** — `statusline.sh` 実行に必要。git 同梱の bash を使う
- **jq** — `statusline.sh` が依存。未導入だと statusline が黙って no-op になる

  ```powershell
  winget install jqlang.jq      # もしくは: scoop install jq
  ```

- **PowerShell** — 5.1 (Windows 標準) もしくは 7.x (Core)。hook の実行に使う

### シェルエイリアスの読み込み（任意）

`claude-o`(Opus) / `claude-ox`(Opus xhigh) / `claude-s`(Sonnet) 等の起動エイリアスを使う場合、
`$PROFILE` に dot-source を追記する:

```powershell
# プロファイルのディレクトリを作成（初回のみ）
New-Item -ItemType Directory -Path (Split-Path $PROFILE) -Force | Out-Null
# 現在実行中の PowerShell 用プロファイルに追記
Add-Content -Path $PROFILE -Value '. "$HOME\.claude\shell\aliases.ps1"'
```

> `$PROFILE` は実行中のバージョン（PowerShell Core = `pwsh.exe` / Windows PowerShell = `powershell.exe`）
> に応じたプロファイルパスを返す。両方使い分けたい場合は、それぞれのターミナルで上記を 1 回ずつ実行する。
> 現在のバージョンは `$PSVersionTable.PSEdition`（`Core` or `Desktop`）で確認できる。

> PowerShell では `alias` 構文に追加引数を渡せないため `function` で定義している。
> `@args` により `claude-s --dangerously-skip-permissions` のような追加フラグも渡せる。

### プラグインの復元

プラグイン本体（`plugins/`）は同期しない。別端末では:

1. マーケットプレイスを追加: `/plugin marketplace add anthropics/claude-plugins-official`
2. `settings.json` の `enabledPlugins` に列挙済みのものを `/plugin install` で導入

### 認証

OAuth トークンは `~/.claude/.credentials.json` に保存され、このリポジトリには含まれない
（`.gitignore` で除外済み）。各端末で `claude` 初回起動時にログインする。

## 日常運用

```bash
cd ~/.claude
git add -A          # allowlist のおかげで設定ファイルだけが対象になる
git commit -m "update settings"
git push

# 別端末側で取り込み
git pull
```
