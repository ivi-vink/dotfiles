export ENV=$HOME/.kshrc
if [ -z $DISPLAY ] && [ $(tty) = /dev/tty1 ]; then
  startx
fi
