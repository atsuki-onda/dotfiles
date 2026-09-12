# zsh-syntax-highlighting (brew)
# 他のすべての設定より後に読み込む必要があるため、.zshrc の最後で source する
__f="${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[ -f "$__f" ] && source "$__f"
unset __f
