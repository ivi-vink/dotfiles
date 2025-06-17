map -docstring "file (default)"           global goto '<a-f>' '<esc>gf'
map -docstring "file (expanded)"          global goto 'f' '<esc>: search-file %val{selection}<ret>'

define-command -docstring \
"search-file <filename>: search for file recusively under path option: %opt{path}" \
search-file -params 1 -override %{ evaluate-commands %sh{
    if [ -n "$(command -v fd)" ]; then                          # create find command template
        find='fd -L --type f "${file}" "${path}"'               # if `fd' is installed it will
    else                                                        # be used because it is faster
        find='find -L "${path}" -mount -type f -name "${file}"' # if not, we fallback to find.
    fi

    file=$(eval echo "$1")

    eval "set -- ${kak_quoted_buflist}"
    while [ $# -gt 0 ]; do            # Check if buffer with this
        if [ "${file}" = "$1" ]; then # file already exists. Basically
            printf "%s\n" "buffer $1" # emulating what edit command does
            exit
        fi
        shift
    done

    if [ -e "${file}" ]; then                     # Test if file exists under
        printf "%s\n" "edit -existing %{${file}}" # servers' working directory
        exit                                      # this is last resort until
    fi                                            # we start recursive searchimg

    # if everthing  above fails - search for file under `path'
    eval "set -- ${kak_quoted_opt_path}"
    while [ $# -gt 0 ]; do                # Since we want to check fewer places,
        case $1 in                        # I've swapped ./ and %/ because
            (./) path=${kak_buffile%/*} ;; # %/ usually has smaller scope. So
            (%/) path=${PWD}            ;; # this trick is a speedi-up hack.
            (*)  path=$1                ;; # This means that `path' option should
        esac                              # first contain `./' and then `%/'

        if [ -z "${file##*/*}" ] && [ -e "${path}/${file}" ]; then
            printf "%s\n" "edit -existing %{${path}/${file}}"
            exit
        else
            # build list of candidates or automatically select if only one found
            # this doesn't support files with newlines in them unfortunately
            IFS='
'
            for candidate in $(eval "${find}"); do
                [ -n "${candidate}" ] && candidates="${candidates} %{${candidate}} %{evaluate-commands %{edit -existing %{${candidate}}}}"
            done

            # we want to get out as early as possible
            # so if any candidate found in current cycle
            # we prompt it in menu and exit
            if [ -n "${candidates}" ]; then
                printf "%s\n" "menu -auto-single ${candidates}"
                exit
            fi
        fi

        shift
    done

    printf "%s\n" "echo -markup %{{Error}unable to find file '${file}'}"
}}
