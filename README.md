# Claude Code グローバル設定

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
| `statusline.sh` | ステータスライン生成スクリプト |
| `.mcp.json` | グローバル MCP サーバ定義 |
| `hooks/` | カスタム hook スクリプト |

> パスはすべて `~/.claude/...`（チルダ表記）なので、ユーザー名が違う端末でもそのまま動く。

## 別端末でのセットアップ（新規）

`~/.claude` がまだ無い、または空の端末:

```bash
git clone git@github.com:Sota6174/claude-config.git ~/.claude
```

`~/.claude` が既に存在する端末（Claude Code 使用済み）は、ディレクトリを消さずに
リポジトリだけ後付けする:

```bash
cd ~/.claude
git init
git remote add origin git@github.com:Sota6174/claude-config.git
git fetch origin
git checkout -t origin/main -f   # 追跡対象の設定ファイルだけ上書きされる（状態ファイルは無傷）
```

### プラグインの復元

プラグイン本体（`plugins/`）は同期しない。別端末では:

1. マーケットプレイスを追加: `/plugin marketplace add anthropics/claude-plugins-official`
2. `settings.json` の `enabledPlugins` に列挙済みのものを `/plugin install` で導入

### 認証

OAuth トークンは macOS Keychain（Linux は `~/.claude/.credentials.json`）に保存され、
このリポジトリには含まれない。各端末で `claude` 初回起動時にログインする。

## 日常運用

```bash
cd ~/.claude
git add -A          # allowlist のおかげで設定ファイルだけが対象になる
git commit -m "update settings"
git push

# 別端末側で取り込み
git pull
```
