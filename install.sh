#!/bin/sh
# links.conf の定義どおりに dotfiles をシンボリックリンクする。
# 既存の実ファイルは *.bak として退避してからリンクを張る(冪等)。
#
# 新しいマシンの初期設定は bootstrap.sh を使う。このスクリプトはリンクだけを扱う。
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# link <リポジトリ内の相対パス> <リンク先の絶対パス>
link() {
  src="$DOTFILES_DIR/$1"
  dest="$2"

  if [ ! -e "$src" ]; then
    echo "skip: $src が無い"
    return
  fi

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

while IFS='|' read -r src dest; do
  case "$src" in ''|\#*) continue ;; esac
  link "$src" "$HOME${dest#\~}"
done < "$DOTFILES_DIR/links.conf"

echo "done."
