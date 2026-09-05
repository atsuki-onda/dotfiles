# 右側の時刻表示は Starship の time モジュール (starship.toml) で行う。
# ここでは Enter を押した瞬間にプロンプトを再描画してから実行するウィジェットだけを定義し、
# スクロールバックに残る時刻が実際のコマンド実行時刻と一致するようにする。
_accept-line-with-time() {
  zle reset-prompt
  zle .accept-line
}
zle -N accept-line _accept-line-with-time
