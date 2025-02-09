export ENV=$HOME/.kshrc
[ -f "$HOME/.config/shell/profile" ] && . "$HOME/.config/shell/profile"
if [ -z $DISPLAY ] && [ $(tty) = /dev/tty1 ]; then
  startx
fi
