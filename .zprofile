# ログインシェルの設定。PATH の組み立てだけを行う。

# Homebrew: Apple Silicon (/opt/homebrew) と Intel (/usr/local) の両方を見る。
# shellenv は brew の bin を PATH の先頭に置くので、brew 版のツール (git など) が
# macOS 同梱版より優先される。
for __brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [ -x "$__brew" ]; then
    eval "$("$__brew" shellenv)"
    break
  fi
done
unset __brew

# ユーザーローカルの実行ファイル。
# ~/.local/bin は Claude Code の公式インストーラの導入先。macOS の path_helper は
# ここを PATH に入れないので自分で足す。brew 版のツールを優先したいので末尾に置く。
for __dir in "$HOME/.local/bin" "$HOME/bin"; do
  if [ -d "$__dir" ]; then
    export PATH="$PATH:$__dir"
  fi
done
unset __dir

# Docker Desktop (入っているマシンだけ)
if [ -d "$HOME/.docker/bin" ]; then
  export PATH="$PATH:$HOME/.docker/bin"
fi
