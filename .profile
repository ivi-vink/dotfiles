export ENV=$HOME/.kshrc
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
gpg-connect-agent updatestartuptty /bye > /dev/null
if [ -z $DISPLAY ] && [ $(tty) = /dev/tty1 ]; then
  startx
fi
