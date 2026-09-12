---
description: この Mac を dotfiles の状態に揃える(bootstrap.sh の実行と検証)
---

`./bootstrap.sh` を実行してこのマシンをセットアップする。

- Bash ツールの `timeout` は 600000 を指定する(Homebrew の導入と `brew bundle` に時間がかかる)
- 途中でユーザーに確認を取らず、最後まで走らせる
- 終了後、`doctor.sh` の出力に `✗` が残っていれば原因を調べて直し、`./bootstrap.sh` を再実行する
- 自動で直せないもの(ネットワーク・認証)はその旨を報告する

最後に、残っている手作業(`gh auth login` / `op signin` / Claude Code のログイン)と
`exec zsh` が必要なことだけを簡潔に伝える。
