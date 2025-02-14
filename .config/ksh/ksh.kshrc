lfcd () {
    tmp="$(mktemp -uq)"
    trap 'rm -f $tmp >/dev/null 2>&1 && trap - HUP INT QUIT TERM PWR EXIT' HUP INT QUIT TERM PWR EXIT
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bind -m ^O=' lfcd^J'

# Emacs mode clear chops off multline prompts.
export PS1="$(hostname):/\$(
root=\$(pwd | cut -d'/' -f2- --output-delimiter '
' | head -n-3 | cut -c1-3 | paste -sd '/')
[ -z \$root ] || echo "\${root}/"
)\$(
pwd | cut -d'/' -f2- --output-delimiter '
' | tail -n3 | paste -sd '/'
)\$(prompt-git)\$(prompt-tf)\n jobs(\j) # "
bind -m ^L="^A^K clear^J"

eval "$(zoxide init posix --cmd cd --hook prompt)"

export HISTFILE="$HOME/.history"
export HISTCONTROL=ignorespace
set -o emacs

