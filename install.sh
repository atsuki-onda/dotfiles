#!/bin/sh
# dotfiles を $HOME にシンボリックリンクする。
# 既存の実ファイルは *.bak として退避してからリンクを張る(冪等)。
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
FILES=".zshrc .zprofile .gitconfig"

for f in $FILES; do
  src="$DOTFILES_DIR/$f"
  dest="$HOME/$f"

  # すでに正しいリンクなら何もしない
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok:   $dest"
    continue
  fi

  # 実ファイル・別リンクが存在する場合は退避
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak"
    echo "back: $dest -> $dest.bak"
  fi

  ln -s "$src" "$dest"
  echo "link: $dest -> $src"
done

echo "done."
