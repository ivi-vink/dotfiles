export ENV=$HOME/.kshrc
[ -f "$HOME/.config/shell/profile" ] && . "$HOME/.config/shell/profile"

if [ -d $HOME/.config/shell/profile.d ]; then
  for i in $HOME/.config/shell/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

if [ -z $DISPLAY ] && [ $(tty) = /dev/tty1 ]; then
  startx
fi
