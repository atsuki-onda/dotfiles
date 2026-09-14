# dotfiles

macOS の個人設定リポジトリ。`$HOME` 以下の設定ファイルをここに集約し、シンボリックリンクで配る。

## 「セットアップして」と言われたら

新しいマシンを丸ごと設定するという意味。次を順に行う。**途中でユーザーに確認を取らず、最後まで走らせる。**

1. `./bootstrap.sh` を実行する
   - Homebrew の導入や `brew bundle` があるため数分かかる。Bash ツールの `timeout` は 600000 を指定する
   - 冪等なので、途中まで済んでいる環境でも安全
2. 終了コードと `doctor.sh` の出力を読む
   - `✗` が残っていれば原因を調べて直し、`./bootstrap.sh` を再実行する
   - ネットワークや認証が原因で自動修復できないものは、そう報告する
3. 最後に次の 2 つだけをユーザーに伝える
   - 残っている手作業（`gh auth login` / `op signin` / Claude Code のログイン）
   - シェルを再読み込みする必要があること（`exec zsh`）

`./doctor.sh` は単体で実行できる検証専用スクリプト。「設定が効いているか確認して」と言われたらこれを使う。

## スクリプトの役割

| スクリプト | 役割 |
|---|---|
| `bootstrap.sh` | 新しいマシン用のエントリポイント。CLT 確認 → Homebrew → `brew bundle` → Oh My Zsh → `install.sh` → Claude Code 設定 → プラグイン → `doctor.sh` |
| `install.sh` | `links.conf` に従ってシンボリックリンクを張るだけ |
| `doctor.sh` | セットアップ結果の検証。不足があれば終了コード 1 |

## 編集するときのルール

- **マシン固有の絶対パスを書かない**。`/Users/onda/...` は `$HOME`、`/opt/homebrew` は `$HOMEBREW_PREFIX`（未設定時のフォールバック付き）を使う。Apple Silicon と Intel の両方で動くこと
- **リンクを増やすときは `links.conf` に 1 行足す**。`install.sh` と `doctor.sh` の両方がこのファイルを読む。スクリプト側にパスを直書きしない
- **shell スクリプトは POSIX sh で書く**。`bootstrap.sh` / `install.sh` / `doctor.sh` は `#!/bin/sh`。`zsh/*.zsh` だけが zsh 依存でよい
- **冪等性を壊さない**。2 回実行しても同じ結果になり、2 回目は何も壊さないこと
- **`zsh/*.zsh` では外部ファイルの存在を確認してから `source` する**。パッケージ未導入でシェルが起動不能になるのを防ぐ
- **PATH は `zsh/path.zsh` に書く**。`.zprofile`（ログインシェル）と `.zshrc`（対話シェル）の
  両方から読まれる。片方だけに書くと、非ログインの対話シェル（別シェルから起動した `zsh`、
  エディタの統合ターミナルなど）でコマンドが見つからなくなる。二重読み込みで PATH が
  重複しないこと
- **シェル設定を変えたら起動経路を両方試す**。`zsh -lic`（ログイン）と `zsh -ic`（非ログイン）。
  `doctor.sh` がこの 2 つを検査する
- 変更したら `sh -n <file>`（zsh なら `zsh -n`）で構文を確認し、`./doctor.sh` を通す

## 管理対象を増やすとき

| 増やすもの | 追記先 |
|---|---|
| 設定ファイル | `links.conf` |
| Homebrew パッケージ | `Brewfile`（`brew bundle dump --file=Brewfile --force` で再生成） |
| Claude Code の設定 | `claude/settings.base.json`（`{{HOME}}` がホームに展開される） |
| Claude Code のプラグイン | `claude/plugins.txt`（マーケットプレイスは `claude/marketplaces.txt`） |

## 管理対象外

`~/.claude/settings.json` のうち `hooks` と `enabledPlugins` はツールが自動生成するため管理しない。
`bootstrap.sh` は `claude/settings.base.json` のキーだけを既存ファイルにマージし、それ以外は温存する。
