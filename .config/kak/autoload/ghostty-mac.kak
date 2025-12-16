provide-module ghostty-mac %{

# termcmd should be set such as the next argument is the whole
# command line to execute
declare-option -docstring %{shell command run to spawn a new terminal
A shell command is appended to the one set in this option at runtime} \
    str termcmd 'open-ghostty'

define-command ghostty-mac-terminal-window -params 1.. -docstring '
ghostty-mac-terminal-window <program> [<arguments>]: create a new terminal as an X11 window
The program passed as argument will be executed in the new terminal' \
%{
    evaluate-commands -save-regs 'a' %{
        set-register a %arg{@}
        evaluate-commands %sh{
            if [ -z "${kak_opt_termcmd}" ]; then
                echo "fail 'termcmd option is not set'"
                exit
            fi
            termcmd=$kak_opt_termcmd
            args=$kak_quoted_reg_a
            unset kak_opt_termcmd kak_quoted_reg_a
            setsid ${termcmd} "$args" < /dev/null > /dev/null 2>&1 &
        }
    }
}
complete-command ghostty-mac-terminal-window shell

define-command ghostty-mac-focus -params ..1 -docstring '
ghostty-mac-focus [<kakoune_client>]: focus a given client''s window
If no client is passed, then the current client is used' \
%{
    evaluate-commands %sh{
        if [ $# -eq 1 ]; then
            printf "evaluate-commands -client '%s' focus" "$1"
        else
            xdotool windowactivate $kak_client_env_WINDOWID > /dev/null ||
            echo 'fail failed to run ghostty-mac-focus, see *debug* buffer for details'
        fi
    }
}
complete-command -menu ghostty-mac-focus client

alias global focus ghostty-mac-focus

}
