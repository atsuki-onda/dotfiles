#!/bin/sh
# dotfiles を各所にシンボリックリンクする。
# 既存の実ファイルは *.bak として退避してからリンクを張る(冪等)。
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# link <リポジトリ内の相対パス> <リンク先の絶対パス>
link() {
  src="$DOTFILES_DIR/$1"
  dest="$2"

  # すでに正しいリンクなら何もしない
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok:   $dest"
    return
  fi

  # 実ファイル・別リンクが存在する場合は退避
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak"
    echo "back: $dest -> $dest.bak"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "link: $dest -> $src"
}

link .zshrc     "$HOME/.zshrc"
link .zprofile  "$HOME/.zprofile"
link .gitconfig "$HOME/.gitconfig"
link ghostty/config.ghostty \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

echo "done."
