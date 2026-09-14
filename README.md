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
6. `~/.claude/settings.json` へ `claude/settings.base.json` をマージ
7. Claude Code のプラグイン導入（`claude/plugins.txt`）
8. `doctor.sh` による検証

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
| `claude/settings.base.json` | Claude Code の設定のうち dotfiles が管理するキー |
| `claude/plugins.txt` | Claude Code のプラグイン一覧 |
| `claude/marketplaces.txt` | プラグインのマーケットプレイス一覧 |
| `links.conf` | シンボリックリンクの定義（`install.sh` と `doctor.sh` が共有） |
| `Brewfile` | Homebrew でインストールしているパッケージ一覧 |

### 管理対象外

`~/.claude/settings.json` の `hooks` と `enabledPlugins` はツールが自動生成するため管理しない。
`bootstrap.sh` は `claude/settings.base.json` のキーだけをマージし、それ以外の値はそのまま残す
（元の内容は `settings.json.bak` に退避される）。

## 更新のしかた

```sh
# Homebrew パッケージ一覧の再生成
brew bundle dump --file=~/dotfiles/Brewfile --force

# 管理対象のファイルを増やす → links.conf に 1 行足して install.sh を実行
```
