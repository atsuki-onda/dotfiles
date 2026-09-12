# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # プロンプトは Starship に任せる (starship.zsh)
plugins=(git copypath aliases)
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"
