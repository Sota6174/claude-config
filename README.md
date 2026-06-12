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
| `shell/aliases.sh` | bash/zsh 共通の起動エイリアス（`claude-o` / `claude-s` 等） |

> パスはすべて `~/.claude/...`（チルダ表記）なので、ユーザー名が違う端末でもそのまま動く。

> **クロスプラットフォーム方針:** 単一 `main` ブランチで全 OS をカバーする。OS 依存は
> `hooks/notify.sh`（通知）の `uname` 分岐に集約し、
> `settings.json` は OS 非依存に保つ。`.gitattributes` で `*.sh` は LF・`*.ps1` は CRLF を強制
> （Windows で `*.sh` が CRLF 化すると shebang が `bash\r` になり Git Bash で壊れるため）。

## 別端末でのセットアップ

### Claude Code のインストール（重要）

**`npm install -g @anthropic-ai/claude-code` は使わない。** mise / nodenv / nvm 等でプロジェクトごとに Node バージョンを pin している環境では、そのディレクトリに入ると `claude` が見つからなくなる（mise シムが拾って `No version is set for shim: claude` エラーになるケースもある）。

代わりに **Node 非依存のネイティブ版インストーラー** を使う:

```bash
curl -fsSL https://claude.ai/install.sh | bash
# → ~/.local/bin/claude にインストールされる
```

mise シムが残っていたら撤去する:

```bash
rm -f ~/.local/share/mise/shims/claude
```

---

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
- **jq の導入が必須**（`statusline.sh` が依存）。未導入だと黙って no-op する:

  ```bash
  winget install jqlang.jq      # もしくは: scoop install jq
  ```

- 通知は `hooks/notify.sh` が `notify.ps1` 経由で Windows バルーンを出す。PowerShell が PATH にあれば追加設定不要。
- `.gitattributes` により `*.sh` は LF で展開される。手動で `core.autocrlf=true` にしていても shebang は壊れない。

### シェルエイリアスの読み込み（任意）

`shell/aliases.sh` の `claude-o`(Opus) / `claude-s`(sonnet) 等の起動エイリアスを使う場合、
`alias` 構文は bash/zsh 共通なので、使うシェルの rc から読み込む（追記は一度だけ）:

```bash
# macOS（zsh）
echo 'source "$HOME/.claude/shell/aliases.sh"' >> ~/.zshrc
# Linux / Windows(Git Bash)（bash）
echo 'source "$HOME/.claude/shell/aliases.sh"' >> ~/.bashrc
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
