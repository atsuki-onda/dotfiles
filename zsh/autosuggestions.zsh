# zsh-autosuggestions (brew)
# 履歴からグレー文字で入力候補を提示。→キーで確定
__f="${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$__f" ] && source "$__f"
unset __f
