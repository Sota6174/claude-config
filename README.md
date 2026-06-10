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

> **クロスプラットフォーム方針:** 単一 `main` ブランチで全 OS をカバーする。OS 依存は
> `hooks/notify.sh`（通知）と `hooks/large-output-nudge.sh`（jq の PATH）の `uname` 分岐に集約し、
> `settings.json` は OS 非依存に保つ。`.gitattributes` で `*.sh` は LF・`*.ps1` は CRLF を強制
> （Windows で `*.sh` が CRLF 化すると shebang が `bash\r` になり Git Bash で壊れるため）。

## 別端末でのセットアップ

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

### Windows (Git Bash) の追加手順

- 操作は **Git Bash** で行う（`~` は `C:\Users\<name>` に解決される）。clone/init 手順は上記と共通。
- **jq の導入が必須**（`statusline.sh` と `large-output-nudge.sh` が依存）。未導入だと両者は黙って no-op する:

  ```bash
  winget install jqlang.jq      # もしくは: scoop install jq
  ```

- 通知は `hooks/notify.sh` が `notify.ps1` 経由で Windows バルーンを出す。PowerShell が PATH にあれば追加設定不要。
- `.gitattributes` により `*.sh` は LF で展開される。手動で `core.autocrlf=true` にしていても shebang は壊れない。

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
