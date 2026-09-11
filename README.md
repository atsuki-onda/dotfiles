# dotfiles

macOS 用の個人設定ファイル。`install.sh` が各ファイルを `$HOME` にシンボリックリンクします。

## 管理対象

| ファイル | 内容 |
|---|---|
| `.zshrc` | zsh の対話シェル設定(エイリアスなど) |
| `.zprofile` | ログインシェル設定(PATH、Homebrew) |
| `.gitconfig` | Git のユーザー情報と credential helper |
| `zsh/` | zsh の設定を機能ごとに分割したファイル群(リンク先: `~/.zsh`) |
| `starship/starship.toml` | Starship プロンプトの設定(リンク先: `~/.config/`) |
| `ghostty/config.ghostty` | Ghostty ターミナルの設定(リンク先: `~/Library/Application Support/com.mitchellh.ghostty/`) |
| `claude/CLAUDE.md` | Claude Code のグローバル指示(リンク先: `~/.claude/`) |
| `claude/statusline.sh` | Claude Code のステータスライン表示スクリプト(リンク先: `~/.claude/`) |
| `Brewfile` | Homebrew でインストールしているパッケージ一覧 |

## 新しいマシンでのセットアップ

```sh
# 1. Homebrew をインストール(未導入の場合)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. リポジトリを取得してリンクを張る
git clone <このリポジトリのURL> ~/dotfiles
cd ~/dotfiles
./install.sh

# 3. パッケージを一括インストール
brew bundle --file=Brewfile
```

`install.sh` は冪等です。既存のファイルがある場合は `*.bak` として退避してからリンクを張ります。

### Claude Code のステータスライン設定

`claude/statusline.sh` は `install.sh` でリンクされますが、これを使わせる設定は
`~/.claude/settings.json` 側にあり、こちらは管理対象外です(`enabledPlugins` や
`hooks` などツールが自動生成する値を含むため)。新しいマシンでは以下を手動で追記します。

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/<ユーザー名>/.claude/statusline.sh"
  }
}
```

## Brewfile の更新

```sh
brew bundle dump --file=~/dotfiles/Brewfile --force
```
