define-command -docstring 'Diff the current selections and display result in a new buffer.' \
diff-selections %{
    evaluate-commands %sh{
        eval set -- "$kak_quoted_selections"

        if [ $# -ge 1 ]; then
            dir=$(mktemp -d -t "kak_diff_XXXXXXX")
            a="$dir/a"
            b="$dir/b"
            result="$dir/result"
            printf "%s" "$1" > "$a"
            printf "%s" "${2:-$kak_reg_d}" > "$b"
            diff -uw "$a" "$b" > "$result"
            printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
                edit -readonly ${result}
                hook -always -once buffer BufClose .* %{ nop %sh{ rm -r ${dir} } }
            }"
        else
            printf "echo -debug 'You must have at least 2 selections to compare.'"
        fi
    }
}
map global user d ':diff-selections<ret>' -docstring 'diff on selections or selection and reg_d'
