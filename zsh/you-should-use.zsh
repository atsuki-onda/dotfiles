# zsh-you-should-use (brew)
# エイリアスが定義済みのコマンドをフルで打つと、エイリアスを教えてくれる
__f="${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-you-should-use/you-should-use.plugin.zsh"
[ -f "$__f" ] && source "$__f"
unset __f
