#!/bin/sh
# 新しい Mac をこのリポジトリの状態に揃える唯一のエントリポイント。
#
#   git clone https://github.com/atsuki-onda/dotfiles.git ~/dotfiles
#   ~/dotfiles/bootstrap.sh
#
# すべての手順は冪等。途中で失敗しても、原因を直して再実行すれば続きから揃う。
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
info() { printf '    %s\n' "$1"; }
warn() { printf '\033[1;33m    ! %s\033[0m\n' "$1"; }

# 致命的でない失敗は記録だけして最後にまとめて報告する。
# 1 つのパッケージが落ちても残りのセットアップは進めたい。
FAILURES=''
record_failure() {
  warn "$1"
  FAILURES="${FAILURES}${1}
"
}

# Homebrew を PATH に載せる。Apple Silicon と Intel の両方を見る。
load_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------- 1. CLT ----
step "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  info "導入済み"
else
  warn "未導入。インストーラを起動する"
  xcode-select --install >/dev/null 2>&1 || true
  warn "GUI のインストールが終わったら ./bootstrap.sh をもう一度実行する"
  exit 1
fi

# ----------------------------------------------------------- 2. Homebrew ----
step "Homebrew"
if load_brew; then
  info "導入済み ($(brew --prefix))"
else
  info "インストールする"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if ! load_brew; then
    warn "brew が見つからない。インストールログを確認する"
    exit 1
  fi
  info "インストール完了 ($(brew --prefix))"
fi

# -------------------------------------------------------- 3. brew bundle ----
step "Homebrew パッケージ (Brewfile)"
# --no-upgrade: 足りないものを入れるだけにする。既存パッケージの更新は
# セットアップの仕事ではない (更新したいときは brew upgrade を明示的に叩く)。
if brew bundle check --no-upgrade --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
  info "すべて導入済み"
else
  if brew bundle install --no-upgrade --file="$DOTFILES_DIR/Brewfile"; then
    info "インストール完了"
  else
    # 1 つの cask が失敗しても残りは進めたい。何が足りないかは doctor.sh が指摘する。
    record_failure "brew bundle に失敗したパッケージがある"
  fi
fi

# --------------------------------------------------------- 4. Oh My Zsh ----
step "Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  info "導入済み"
else
  # KEEP_ZSHRC: この後で dotfiles の .zshrc をリンクするので上書きさせない
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  info "インストール完了"
fi

# ------------------------------------------------------------- 5. リンク ----
step "シンボリックリンク"
"$DOTFILES_DIR/install.sh"

# --------------------------------------------------- 6. Claude Code ----
step "Claude Code"
if command -v claude >/dev/null 2>&1; then
  info "導入済み ($(claude --version 2>/dev/null | head -1))"
else
  # Homebrew の cask ではなく公式インストーラで入れる (自動更新に乗るため)。
  # インストール先は ~/.local/bin。PATH は .zprofile が通す。
  info "公式インストーラで導入する"
  if curl -fsSL https://claude.ai/install.sh | bash; then
    PATH="$HOME/.local/bin:$PATH"
    export PATH
    info "インストール完了"
  else
    record_failure "Claude Code の導入に失敗した"
  fi
fi

# --------------------------------------------- 7. Claude Code プラグイン ----
step "Claude Code のプラグイン"
if ! command -v claude >/dev/null 2>&1; then
  record_failure "claude コマンドが無いためプラグインを導入できない"
else
  # マーケットプレイスを先に登録する (登録済みなら失敗するので握りつぶす)
  while read -r market; do
    case "$market" in ''|\#*) continue ;; esac
    claude plugin marketplace add "$market" >/dev/null 2>&1 || true
  done < "$DOTFILES_DIR/claude/marketplaces.txt"

  installed="$HOME/.claude/plugins/installed_plugins.json"
  while read -r plugin; do
    case "$plugin" in ''|\#*) continue ;; esac
    if [ -f "$installed" ] && command -v jq >/dev/null 2>&1 &&
       jq -e --arg p "$plugin" '.plugins | has($p)' "$installed" >/dev/null 2>&1; then
      info "ok:   $plugin"
    elif claude plugin install "$plugin" --scope user --yes >/dev/null 2>&1; then
      info "add:  $plugin"
    else
      record_failure "プラグインの導入に失敗: $plugin"
    fi
  done < "$DOTFILES_DIR/claude/plugins.txt"
fi

# ------------------------------------------------------------- 8. 検証 ----
"$DOTFILES_DIR/doctor.sh" || true

# ------------------------------------------------------------- 9. 結果 ----
step "残りの手作業"
cat <<'MANUAL'
    以下は認証が必要なため自動化できない。必要になったときに実行する。

      gh auth login              GitHub CLI (git の credential helper に使う)
      op signin                  1Password CLI
      claude                     Claude Code の初回ログイン

    Ghostty はフォント "PlemolJP Console NF" を使う。Brewfile で導入済み。
MANUAL

if [ -n "$FAILURES" ]; then
  printf '\n\033[1;33m==> 失敗した手順\033[0m\n'
  printf '%s' "$FAILURES" | sed 's/^/    - /'
  printf '\n    原因を直して ./bootstrap.sh を再実行する。\n'
  exit 1
fi

step "完了"
info "新しいシェルを開く: exec zsh"
