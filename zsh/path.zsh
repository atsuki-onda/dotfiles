# PATH の組み立て。
# ログインシェル (.zprofile) と対話シェル (.zshrc) の両方から読まれる。
# 非ログインの対話シェルは .zprofile を読まないため、片方だけに書くと
# そのシェルで brew や ~/.local/bin のコマンドが見つからなくなる。
# 二重に読まれても PATH が重複しないようにしてある。

# Homebrew: Apple Silicon (/opt/homebrew) と Intel (/usr/local) の両方を見る。
# shellenv は brew の bin を PATH の先頭に置くので、brew 版のツール (git など) が
# macOS 同梱版より優先される。
if [ -z "${HOMEBREW_PREFIX:-}" ]; then
  for __brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$__brew" ]; then
      eval "$("$__brew" shellenv)"
      break
    fi
  done
  unset __brew
fi

# 末尾に足す。brew 版のツールを優先したいので先頭には置かない。
__path_append() {
  case ":$PATH:" in
    *":$1:"*) return 0 ;;                      # すでに入っている
  esac
  [ -d "$1" ] && export PATH="$PATH:$1"
  return 0
}

__path_append "$HOME/.local/bin"   # Claude Code の公式インストーラの導入先
__path_append "$HOME/bin"
__path_append "$HOME/.docker/bin"  # Docker Desktop

unset -f __path_append
