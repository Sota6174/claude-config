# 既存スタックの検出

実装/修正提案の品質は、**「対象プロジェクトの実際の技術スタックとバージョンを正しく把握できているか」** に強く依存する。古いメジャーバージョンに合わない最新の公式 BP を当てはめると、提案が壊れる。

## 検出の優先順位

```
ロックファイル（実際のバージョン）> マニフェスト（宣言） > README > 推測
```

### 1. ロックファイル（最優先）

実際にインストールされているバージョンを確定的に知れる：

| エコシステム | ロックファイル |
|---|---|
| Node.js (npm) | `package-lock.json` |
| Node.js (yarn) | `yarn.lock` |
| Node.js (pnpm) | `pnpm-lock.yaml` |
| Python | `poetry.lock`, `Pipfile.lock`, `uv.lock`, `requirements.txt`（pin 済の場合） |
| Go | `go.sum` |
| Rust | `Cargo.lock` |
| Java | `*.gradle.lock` / Maven の `<dependencyManagement>` |
| Ruby | `Gemfile.lock` |

### 2. パッケージマニフェスト

範囲指定（`^1.2.0` 等）の場合はロックファイルで確定値を取る。マニフェストだけ見て「最新が入っている」と推測しないこと。

- `package.json` の `dependencies` / `devDependencies`
- `pyproject.toml` の `[project.dependencies]` / `tool.poetry.dependencies`
- `requirements.txt`
- `go.mod`
- `Cargo.toml`
- `pom.xml`

### 3. ランタイム / 言語バージョン

- `.node-version` / `.nvmrc` / `package.json` の `engines`
- `.python-version` / `pyproject.toml` の `python` 指定
- `go.mod` の `go` ディレクティブ
- `rust-toolchain.toml`
- `Dockerfile` の `FROM` 行

### 4. 設定ファイル（フレームワーク固有の挙動を把握）

| 設定ファイル | 何が分かるか |
|---|---|
| `tsconfig.json` | TypeScript の strictness, target, JSX 設定 |
| `next.config.js` / `next.config.ts` | App Router / Pages Router, experimental flags |
| `vite.config.ts` | Vite プラグイン構成 |
| `webpack.config.js` | バンドラ設定 |
| `.eslintrc.*` / `eslint.config.*` | コーディング規約 |
| `.prettierrc` | フォーマット規約 |
| `pytest.ini` / `pyproject.toml [tool.pytest.ini_options]` | テスト設定 |
| `jest.config.*` / `vitest.config.*` | JS テスト設定 |
| `tailwind.config.*` | Tailwind 利用 |

### 5. README / CLAUDE.md / docs/

- `README.md`：プロジェクトの目的・セットアップ手順から技術スタックを把握
- `CLAUDE.md`：このプロジェクト固有の規約・運用ルール（最優先で従う）
- `docs/best-practices/<tech>.md`：プロジェクト固有の BP（**公式 BP より優先する場面が多い**）
- `docs/architecture/` 等：設計判断の記録

---

## バージョンを確定したら必ずやること

1. **対象バージョンが公式サポート期間内か確認** — EOL 済みの古いバージョンに最新 BP は通用しない
2. **次のメジャーバージョンの予定を確認** — Release Notes で破壊的変更が予告されていれば、選ぶ実装パターンが変わる
3. **lockfile と マニフェストの食い違いに注意** — マニフェストが `^1.0.0` でロックが `1.5.3` ならロック側を採用

---

## 既存パターンの抽出

スタック把握が終わったら、修正対象の **周辺コード** から既存パターンを抽出する：

| 抽出対象 | 抽出方法 |
|---|---|
| 命名規則 | 既存の類似機能のファイル名・関数名を Grep |
| ファイル構成 | 同じ層（コンポーネント/サービス/DB アクセス等）の他ファイルを Glob |
| エラーハンドリング | `catch` や `try` / Go の `if err != nil` パターンを Grep |
| ロギング | `console.log` / `logger.` / `log.` 等を Grep |
| 依存性注入パターン | コンテナ・モジュール構成を確認 |
| テスト構造 | 既存テストの記述スタイルを1〜2例読む |

**抽出のコツ：**
- 「最も新しく書かれたファイル」を `ls -t` や `git log` で見つけて、そこを基準にする（古い箇所はリファクタ予定の可能性）
- 同じパターンが複数箇所にあれば、それが「採用済みのパターン」
- 1箇所にしかないパターンは「実験中 / 未完成 / 例外」の可能性、安易に踏襲しない

---

## やってはいけない検出パターン

- ❌ マニフェストだけ見てバージョン確定したつもりになる
- ❌ README に書かれた技術スタックを信じて実コードを確認しない
- ❌ 1つのファイルだけ見て「これがプロジェクト全体のパターンだ」と判断する
- ❌ `node_modules` や `vendor` を直接読みに行く（時間の無駄、公式ドキュメントを取るべき）

---

## 把握結果のサマリフォーマット

提案前に必ず以下を明示する：

```markdown
## 既存スタックの把握

- 言語/ランタイム：<例> TypeScript 5.4 / Node 20.11
- フレームワーク（バージョン込み）：
  - <例> Next.js 15.0.3 (App Router) — `next.config.ts` で `experimental.serverActions` 有効
  - <例> Prisma 5.20.0 — schema は `prisma/schema.prisma`
- テスト：<例> Vitest 1.6.0 + Playwright 1.45
- プロジェクト固有 BP：`docs/best-practices/nextjs.md`（あれば内容も要約）
- 既存の主要パターン：
  - <例> ルートハンドラは `app/api/<resource>/route.ts` 配下
  - <例> エラーは `lib/errors.ts` の `AppError` を throw する
```

これがあると、後段の方針提示の根拠が明確になる。
