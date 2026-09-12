# Homebrew の PATH を確実にする。
# 通常は .zprofile (ログインシェル) が brew shellenv を評価するが、非ログインの
# 対話シェルでは走らない。他の設定が $HOMEBREW_PREFIX に依存するのでここで補う。
if [ -z "${HOMEBREW_PREFIX:-}" ]; then
  for __brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$__brew" ]; then
      eval "$("$__brew" shellenv)"
      break
    fi
  done
  unset __brew
fi
