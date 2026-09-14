#!/bin/sh
# セットアップ結果を検証する。bootstrap.sh の最後から呼ばれるが、単体でも実行できる。
# 1 つでも不足があれば終了コード 1。
set -u

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
NG=0

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
ok()   { printf '    \033[32m✓\033[0m %s\n' "$1"; }
ng()   { printf '    \033[31m✗\033[0m %s\n' "$1"; NG=1; }
note() { printf '    \033[33m-\033[0m %s\n' "$1"; }

# ------------------------------------------------------------- リンク ----
step "シンボリックリンク"
while IFS='|' read -r src dest; do
  case "$src" in ''|\#*) continue ;; esac
  target="$HOME${dest#\~}"
  expected="$DOTFILES_DIR/$src"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$expected" ]; then
    ok "$src"
  else
    ng "$src -> $target (リンクされていない)"
  fi
done < "$DOTFILES_DIR/links.conf"

# --------------------------------------------------------- パッケージ ----
step "Homebrew パッケージ"
if command -v brew >/dev/null 2>&1; then
  if brew bundle check --no-upgrade --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
    ok "Brewfile のパッケージはすべて導入済み"
  else
    ng "不足がある:"
    brew bundle check --no-upgrade --file="$DOTFILES_DIR/Brewfile" --verbose 2>&1 | sed 's/^/      /'
  fi
else
  ng "brew が PATH に無い"
fi

# ------------------------------------------------------------- コマンド ----
step "コマンド"
for cmd in git gh node pnpm starship jq claude op; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd"
  else
    ng "$cmd が見つからない"
  fi
done

# ----------------------------------------------------------------- zsh ----
step "zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then ok "Oh My Zsh"; else ng "Oh My Zsh が無い"; fi

BREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null || echo /opt/homebrew)}"
for plug in \
  "zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "zsh-you-should-use/you-should-use.plugin.zsh"
do
  if [ -f "$BREW_PREFIX/share/$plug" ]; then
    ok "${plug%%/*}"
  else
    ng "${plug%%/*} が $BREW_PREFIX/share に無い"
  fi
done

case "${SHELL:-}" in
  */zsh) ok "ログインシェルは zsh" ;;
  *)     ng "ログインシェルが zsh ではない (${SHELL:-unset}) → chsh -s /bin/zsh" ;;
esac

# 起動経路ごとにコマンドが引けるか。非ログインの対話シェルは .zprofile を読まないので、
# PATH をそこだけに書いていると落ちる。実際に一度この穴を踏んでいる。
check_shell() {
  label="$1"
  mode="$2"
  if env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin /bin/zsh "$mode" \
       'command -v claude >/dev/null && command -v starship >/dev/null' >/dev/null 2>&1; then
    ok "${label}で claude / starship が引ける"
  else
    ng "${label}で claude / starship が引けない → zsh/path.zsh を確認"
  fi
}
check_shell "ログインシェル" -lic
check_shell "非ログインの対話シェル" -ic

# --------------------------------------------------------- Claude Code ----
step "Claude Code"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLAUDE_BASE="$DOTFILES_DIR/claude/settings.base.json"
if ! command -v jq >/dev/null 2>&1; then
  ng "jq が無いため settings.json を検証できない"
elif [ ! -f "$CLAUDE_SETTINGS" ]; then
  ng "$CLAUDE_SETTINGS が無い"
else
  # base の全キーが実際の settings.json に反映されているか (包含関係) を見る
  if jq -e -s --arg home "$HOME" '
        (.[1] | walk(if type == "string" then gsub("\\{\\{HOME\\}\\}"; $home) else . end)) as $want
        | (.[0] * $want) == .[0]
      ' "$CLAUDE_SETTINGS" "$CLAUDE_BASE" >/dev/null 2>&1; then
    ok "settings.json に dotfiles の設定が反映されている"
  else
    ng "settings.json が settings.base.json と一致しない → ./bootstrap.sh"
  fi
fi

if [ -x "$HOME/.claude/statusline.sh" ]; then
  ok "statusline.sh に実行権限がある"
else
  ng "statusline.sh に実行権限が無い → chmod +x claude/statusline.sh"
fi

INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
while read -r plugin; do
  case "$plugin" in ''|\#*) continue ;; esac
  if [ -f "$INSTALLED" ] && command -v jq >/dev/null 2>&1 &&
     jq -e --arg p "$plugin" '.plugins | has($p)' "$INSTALLED" >/dev/null 2>&1; then
    ok "$plugin"
  else
    ng "$plugin が未導入"
  fi
done < "$DOTFILES_DIR/claude/plugins.txt"

# ------------------------------------------------------------- 認証 ----
step "認証 (手作業。未認証でも致命的ではない)"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  ok "gh は認証済み"
else
  note "gh が未認証 → gh auth login"
fi
if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1 &&
   [ -n "$(op account list 2>/dev/null)" ]; then
  ok "1Password CLI にアカウントが登録されている"
else
  note "1Password CLI が未設定 → op signin"
fi

# ------------------------------------------------------------- 結果 ----
if [ "$NG" -eq 0 ]; then
  printf '\n\033[1;32m==> 問題なし\033[0m\n'
else
  printf '\n\033[1;31m==> 不足あり (上の ✗ を参照)\033[0m\n'
fi
exit "$NG"
