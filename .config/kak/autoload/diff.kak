define-command -override -docstring 'Diff the current selections and display result in a new buffer.' \
diff-selections %{
    evaluate-commands %sh{
        eval set -- "$kak_quoted_selections"

        diff_dance()
        {
          dir=$(mktemp -d -t "kak_diff_XXXXXXX")
          a="$dir/a"
          b="$dir/b"
          result="$dir/result.diff"
          printf "%s" "$1" > "$a"
          printf "%s" "$2" > "$b"
          diff -U10000 -w "$a" "$b" > "$result"
          [ "$3" ] && $3 "$result"
          printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
              edit -readonly ${result}
              hook -always -once buffer BufClose .* %{ nop %sh{ rm -r ${dir} } }
          }"
        }


        if [ $# -gt 1 ]
        then
          diff_dance "$@"
          exit 0
        fi

        # /home/ivi/.local/src/vial-qmk/keyboards/42keebs/cantor_pro/keymaps/my/keymap.c:98.1,120.3
        if [ "$kak_reg_D" ] && [ "${1}" ]
        then
          selection_content="${kak_reg_D#*
}"
          info="${kak_reg_D%%
*}"
          file_name_a="${info%:*}"
          selection_a="${info#*:}"
          range_start_a="${selection_a%,*}"
          range_end_a="${selection_a#*,}"
          line_start_a="${range_start_a%%.*}"
          line_end_a="${range_end_a%.*}"
          if [ "$line_start_a" -gt "$line_end_a" ]
          then swapme="$line_start_a"
               line_start_a="$line_end_a"
               line_end_a="$swapme"
          fi
          delta_a="$(( line_end_a - line_start_a ))"
          diff_lines="@@ -${line_start_a},${delta_a} "

          file_name_b="${kak_buffile}"
          range_start_b="${kak_selection_desc%,*}"
          range_end_b="${kak_selection_desc#*,}"
          line_start_b="${range_start_b%%.*}"
          line_end_b="${range_end_b%.*}"
          if [ "$line_start_b" -gt "$line_end_b" ]
          then swapme="$line_start_b"
               line_start_b="$line_end_b"
               line_end_b="$swapme"
          fi
          delta_b="$(( line_end_b - line_start_b ))"
          diff_lines="${diff_lines}+${line_start_b},${delta_b} @@"

          put_original_files() {
            result="${1:?require result file}"
            sed -i.bak 's/^@@.*@@/'"$diff_lines"'/g' "${result}" >/dev/null
            sed -i.bak 's,^--- .*/a,--- '"$file_name_a"',g' "${result}" >/dev/null
            sed -i.bak 's,^+++ .*/b,+++ '"$file_name_b"',g' "${result}" >/dev/null
          }
          diff_dance "$selection_content" "$1" put_original_files
        fi
    }
}

declare-user-mode diff

define-command -override -docstring 'Diff this.' \
diff-this %{
  set-register D "%val{buffile}:%val{selection_desc}
%val{selection}"
}


define-command -override -hidden -docstring 'Enter diff mode!' \
enter-diff-mode %{
  evaluate-commands %sh{
    printf 'enter-user-mode diff'
  }
}
map global user d ':enter-diff-mode<ret>' -docstring 'Mappings for interacting with diffs!'
map global diff s ':diff-selections<ret>' -docstring 'diff on selections or selection and reg_d'
map global diff t ':diff-this<ret>' -docstring 'diff on selections or selection and reg_d'
