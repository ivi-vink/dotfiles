#!/bin/sh
f="${XDG_CONFIG_HOME:=$HOME/.config}/emacs/my-fifo"
if [ -e "$f" ]
then rm "$f"
fi
mkfifo -m600 "$f"

cat | cat >"$f" &

emacsclient --eval "(my/pick-line-from-shell \"cat <'$f'; rm '$f'\")" | jq -r

wait
