# dotfiles

macOS 用の個人設定ファイル。`install.sh` が各ファイルを `$HOME` にシンボリックリンクします。

## 管理対象

| ファイル | 内容 |
|---|---|
| `.zshrc` | zsh の対話シェル設定(エイリアスなど) |
| `.zprofile` | ログインシェル設定(PATH、Homebrew) |
| `.gitconfig` | Git のユーザー情報と credential helper |
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

## Brewfile の更新

```sh
brew bundle dump --file=~/dotfiles/Brewfile --force
```
