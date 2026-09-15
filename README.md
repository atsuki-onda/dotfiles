# dotfiles

macOS 用の個人設定ファイル。新しいマシンでは `bootstrap.sh` を 1 回叩けば設定が揃う。

## 新しいマシンでのセットアップ

```sh
git clone https://github.com/atsuki-onda/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
```

Claude Code から行う場合は、`~/dotfiles` を開いて「セットアップして」または `/setup` と言えばよい
（手順はリポジトリ直下の `CLAUDE.md` に書いてある）。

`bootstrap.sh` が行うこと:

1. Xcode Command Line Tools の確認
2. Homebrew の導入（Apple Silicon / Intel の両対応）
3. `brew bundle`（`Brewfile` のパッケージ一括インストール）
4. Oh My Zsh の導入
5. `install.sh`（`links.conf` に従ってシンボリックリンク）
6. Claude Code のプラグイン導入（`claude/plugins.txt`）
7. `doctor.sh` による検証

すべて冪等。既存のファイルがある場合は `*.bak` として退避してからリンクを張る。

### 自動化できない手作業

認証が絡むため、必要になったときに手で実行する。

```sh
gh auth login    # GitHub CLI (git の credential helper に使う)
op signin        # 1Password CLI
claude           # Claude Code の初回ログイン
```

## 検証

```sh
~/dotfiles/doctor.sh
```

リンク・パッケージ・zsh プラグイン・Claude Code の設定とプラグインが揃っているかを一覧表示する。
不足があれば終了コード 1。

## 管理対象

| ファイル | 内容 |
|---|---|
| `.zshrc` | zsh の対話シェル設定の目次（実体は `zsh/`） |
| `.zprofile` | ログインシェル設定（`zsh/path.zsh` を読むだけ） |
| `.gitconfig` | Git のユーザー情報と credential helper |
| `git/ignore` | グローバル gitignore（リンク先: `~/.config/git/`） |
| `zsh/` | zsh の設定を機能ごとに分割したファイル群（リンク先: `~/.zsh`）。`path.zsh` は `.zprofile` と `.zshrc` の両方から読まれる |
| `starship/starship.toml` | Starship プロンプトの設定（リンク先: `~/.config/`） |
| `ghostty/config.ghostty` | Ghostty ターミナルの設定（リンク先: `~/Library/Application Support/com.mitchellh.ghostty/`） |
| `claude/CLAUDE.md` | Claude Code のグローバル指示（リンク先: `~/.claude/`） |
| `claude/statusline.sh` | Claude Code のステータスライン表示スクリプト（リンク先: `~/.claude/`） |
| `claude/settings.json` | Claude Code の設定（リンク先: `~/.claude/`）。`hooks` を含めて丸ごと管理する |
| `claude/plugins.txt` | Claude Code のプラグイン一覧 |
| `claude/marketplaces.txt` | プラグインのマーケットプレイス一覧 |
| `links.conf` | シンボリックリンクの定義（`install.sh` と `doctor.sh` が共有） |
| `Brewfile` | Homebrew でインストールしているパッケージ一覧 |

### settings.json の扱い

`~/.claude/settings.json` は `claude/settings.json` へのシンボリックリンク。`hooks` や
`enabledPlugins` を含めて丸ごと git 管理する。そのため次の 2 点に注意する。

- Claude Code や Orca がこのファイルを書き換えると、そのままリポジトリの差分になる。
  `git diff` に身に覚えのない変更が出たら、それはツールの自動更新である
- `hooks` は Orca が生成したもので `${HOME}` 参照しか含まない。Orca が入っていない
  マシンでも、hook 側がスクリプトの存在を確認してから実行するので害はない

`claude/plugins.txt` は `enabledPlugins` と重複して見えるが役割が違う。設定キーを配るだけでは
プラグインの実体は落ちてこないので、`bootstrap.sh` が `plugins.txt` を見てインストールする。

## 更新のしかた

```sh
# Homebrew パッケージ一覧の再生成
brew bundle dump --file=~/dotfiles/Brewfile --force

# 管理対象のファイルを増やす → links.conf に 1 行足して install.sh を実行
```
