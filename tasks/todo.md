# dotfiles ワンコマンドセットアップ化

`git clone` → Claude Code で「セットアップして」だけで新しい Mac を設定し終える。

## タスク

- [x] `bootstrap.sh` を追加(CLT → Homebrew → brew bundle → Oh My Zsh → install.sh → Claude 設定 → プラグイン → doctor)
- [x] `doctor.sh` を追加(セットアップ結果の検証)
- [x] `claude/settings.base.json` を追加(管理する Claude Code 設定。既存 settings.json へ jq でマージ)
- [x] `claude/plugins.txt` / `claude/marketplaces.txt` を追加(プラグインの復元)
- [x] `install.sh` をシンボリックリンク専任にする(Oh My Zsh 導入は bootstrap へ移動)
- [x] マシン固有パスの排除
  - [x] `.zprofile`: `/Users/onda/.docker/bin` → `$HOME`、Homebrew は Apple Silicon / Intel 両対応
  - [x] `zsh/*.zsh`: `/opt/homebrew/share/...` → `$HOMEBREW_PREFIX` + 存在ガード
  - [x] `.gitconfig`: `/opt/homebrew/bin/gh` → PATH 上の `gh`
- [x] `Brewfile` に `jq` を追加
- [x] リポジトリ直下の `CLAUDE.md` を追加(「セットアップして」の定義)
- [x] `.claude/commands/setup.md` を追加(`/setup`)
- [x] `README.md` を更新
- [x] 検証(shellcheck 相当の構文チェック + doctor.sh を現マシンで実行 + 設定マージのドライラン)

## レビュー

### 結果

`git clone` → Claude Code で「セットアップして」だけで完了する状態にした。
エントリポイントは `bootstrap.sh` の 1 本、検証は `doctor.sh`。

### 追加・変更したファイル

| ファイル | 変更 |
|---|---|
| `bootstrap.sh` | 新規。CLT → Homebrew → brew bundle → Oh My Zsh → install.sh → Claude Code 本体 → 設定マージ → プラグイン → doctor |
| `doctor.sh` | 新規。リンク・パッケージ・コマンド・zsh・Claude 設定/プラグイン・認証を検証 |
| `links.conf` | 新規。リンク定義を install.sh と doctor.sh で共有し、二重管理をなくした |
| `install.sh` | links.conf を読むだけに縮小。Oh My Zsh 導入は bootstrap へ移動 |
| `claude/settings.base.json` | 新規。管理するキーだけを持ち、`{{HOME}}` を展開して既存 settings.json に jq でマージ |
| `claude/plugins.txt` / `claude/marketplaces.txt` | 新規。プラグイン 5 つを復元 |
| `CLAUDE.md` (直下) | 新規。「セットアップして」の定義と編集ルール |
| `.claude/commands/setup.md` | 新規。`/setup` |
| `.zprofile` | Homebrew を Apple Silicon / Intel 両対応に。`/Users/onda/.docker/bin` → `$HOME`。`~/.local/bin` を PATH に追加 |
| `zsh/homebrew.zsh` | 新規。非ログインシェルでも `$HOMEBREW_PREFIX` を確定させる |
| `zsh/*.zsh` | `/opt/homebrew` 直書きをやめ、存在確認してから source |
| `.gitconfig` | `/opt/homebrew/bin/gh` → PATH 上の `gh` |
| `Brewfile` | `jq` を追加、`cask "claude-code"` を削除(公式インストーラ管理に移行済みのため) |
| `git/ignore` | 新規。`~/.config/git/ignore`(グローバル gitignore)を管理下に追加 |
| `README.md` | bootstrap 一本の手順に更新 |

### 見つけて直した移植性の問題

- `~/.local/bin` が macOS の path_helper では PATH に入らず、クリーンなログインシェルから
  `claude` が引けなかった(現在の環境では Orca が PATH を足していただけだった)。`.zprofile` で解決
- `zsh/*.zsh` が `/opt/homebrew/share/...` を無条件 source していたため、パッケージ未導入の
  マシンではシェル起動時にエラーになる状態だった
- `~/.config/git/ignore` が未管理だった。無いと新マシンで `.claude/settings.local.json` が
  各リポジトリにコミットされてしまう
- `Brewfile` の `cask "claude-code"` は既に実体が無く(ネイティブインストーラへ移行済み)、
  brew bundle で二重インストールになるため削除

### 検証したこと

- `sh -n` / `zsh -n` による全スクリプトの構文チェック
- `bootstrap.sh` を実機で通しで実行 → 終了コード 0、doctor は「問題なし」
- 仮想 HOME での `install.sh`: 新規リンク作成、既存実ファイルの `.bak` 退避
- 仮想 HOME での `doctor.sh`: 不足を正しく `✗` 検出
- settings.json マージ: (a) 空 `{}` から生成、(b) 既存 `hooks` / `enabledPlugins` の温存、
  (c) 現行設定に対して差分なし
- brew 未導入を模擬した環境で `zsh/*.zsh` が壊れずに読み込まれること
- クリーンなログインシェル (`env -i zsh -lc`) で `claude` / `starship` / `HOMEBREW_PREFIX` が解決すること
- `git credential fill` が PATH 上の `gh` 経由で通ること

### 補足

- `brew bundle` は `--no-upgrade` で実行する。セットアップは不足分の導入のみを行い、
  既存パッケージの更新はしない(更新は `brew upgrade` を明示的に叩く)
- `jq` は macOS 15 以降なら `/usr/bin/jq` があるが、古い macOS を考慮して Brewfile に入れた

---

# settings.json を丸ごとリンク管理に切り替え

**2026-09-15 / 依頼: 「claude の settings.json もドットファイルに入れてほしい」**

## 経緯

調査の結果、`~/.claude/settings.json` の中身は既にすべて管理下にあった
（`settings.base.json` + `plugins.txt` + `marketplaces.txt`）。足りなかったのは
**リポジトリへの書き戻し**で、`/config` などで設定を変えても dotfiles に反映されなかった。

方式を 2 つ提示し、「丸ごとリンク管理」が選ばれた。

## タスク

- [x] `claude/settings.json` を追加（現行の `~/.claude/settings.json` を丸ごと）
- [x] `statusLine.command` の絶対パスを `$HOME/.claude/statusline.sh` に置換
- [x] `links.conf` に 1 行追加
- [x] `bootstrap.sh` のセクション 7（jq マージ）を削除、以降の番号を繰り上げ
- [x] `doctor.sh` の包含チェックを JSON 妥当性チェックに置換
- [x] `claude/settings.base.json` を削除
- [x] `CLAUDE.md` / `README.md` を更新
- [x] 実機で検証

## レビュー

### 検証したこと

ドキュメントに書かれていない挙動が 2 つあったので、どちらも実測した。

| 確かめたこと | 方法 | 結果 |
|---|---|---|
| `statusLine.command` で `$HOME` が展開されるか | `sh -c 'echo {} \| $HOME/.claude/statusline.sh'` | 展開される。終了コード 0 で描画も正常。公式ドキュメントにも「command はシェル経由で実行される」と明記 |
| Claude Code の書き込みがリンクを壊さないか | `claude plugin disable/enable swift-lsp` で往復 | **リンクは保持され、リポジトリ側のファイルが直接書き換わった**。往復後の md5 は完全一致 |
| 他キーが書き込みで失われないか | 同上 | `$HOME` 表記を含め全キーが保持された |

加えて `sh -n` で全スクリプトの構文チェック、`./doctor.sh` は「問題なし」（終了コード 0）。

### この方式のトレードオフ

- **利点**: 書き戻しの仕組みが要らない。設定を変えればそのまま `git diff` に出る
- **欠点**: Claude Code や Orca の自動更新がそのままリポジトリの差分になる。
  `hooks`（Orca 生成・約 37KB）が変わるたびにノイズが出る

### 注意点

リンク管理では `{{HOME}}` のようなテンプレート展開が効かない。`settings.json` に
絶対パスを書くときは `$HOME` を使う（シェルが解釈するキーに限る）。
