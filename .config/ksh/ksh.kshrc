if SOME_VARIABLE=`push.sh 2>/dev/null`
then	eval "$SOME_VARIABLE"
else	echo "push.sh not installed" >&2; exit 1
fi

..() { set -- ".." "$@"; for up; do cd $up; done; }

lfcd () {
    tmp="$(mktemp -uq)"
    trap 'rm -f $tmp >/dev/null 2>&1 && trap - HUP INT QUIT TERM PWR EXIT' HUP INT QUIT TERM PWR EXIT
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bind -m ^O=' mcd^J'
bind -m ^X^F=' REPLY="$(vis-open .)"; [ -z "$REPLY" ] || cd "$REPLY"^J'

# Emacs mode clear chops off multline prompts.
export PS1="$(hostname):\$(pwd-short)\$(prompt-git)\$(prompt-tf)\n jobs(\j) # "
bind -m ^L="^A^K clear^J"

export HISTFILE="$HOME/.history"
export HISTCONTROL=ignorespace
export HISTSIZE=100000

[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc"

set -o emacs
[ -f /run/.containerenv ] && [ -n "$PNSH_KAK_AUTOSTART" ] && {
    ks s 2>&1 >/dev/null || kc s
}
