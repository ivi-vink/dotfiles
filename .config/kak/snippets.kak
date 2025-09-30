echo "sourced snippets"

map buffer normal <a-f> ": phantom-selection-iterate-next<ret>"
map buffer normal <a-F> ": phantom-selection-iterate-prev<ret>"
map buffer insert <a-f> "<esc>: try phantom-selection-iterate-next<ret>i"
map buffer insert <a-F> "<esc>: try phantom-selection-iterate-prev<ret>i"

set buffer snippets 'iAnf' '//' %{
  phantom-selection-clear
  snippets-insert %@\frac{ ${} }{ ${} } ${}@
  phantom-selection-add-selection
  phantom-selection-iterate-next
}
set -add buffer snippets 'iAsf' %<((\d+)|(\d*)(\\)?([A-Za-z]+)((\^|_)(\{\d+\}|\d))*)/> %{
  phantom-selection-clear
  snippets-insert "\frac{%reg{1}}{ ${} } ${}"
  phantom-selection-add-selection
  phantom-selection-iterate-next
}
set -add buffer snippets 'iAbf' '([^\n]+\))/' %{
  phantom-selection-clear

  exec "i%reg{1}<esc>hm_"
  exec %{"sd}
  snippets-insert "\frac{%reg{s}}{ ${} } ${}"

  phantom-selection-add-selection
  phantom-selection-iterate-next
}
set -add buffer snippets 'sfrac' '/s' %{
  phantom-selection-clear
  snippets-insert "\frac{%reg{dquote}}{ ${} } ${}"
  phantom-selection-add-selection
  phantom-selection-iterate-next
}

set -add buffer snippets '^2' 'sr' %{
  snippets-insert "^2"
}
set -add buffer snippets '^3' 'cb' %{
  snippets-insert "^3"
}
set -add buffer snippets 'superscript' 'td' %{
  phantom-selection-clear
  snippets-insert "^{ ${value} } ${}"
  phantom-selection-add-selection
  phantom-selection-iterate-next
}

set -add buffer snippets 'subscript' '([A-Za-z])(\d)' %{
  snippets-insert "%reg{1}_{%reg{2}} ${}"
}
set -add buffer snippets 'subscript2' '([A-Za-z])_(\d\d)' %{
  snippets-insert "%reg{1}_{%reg{2}} ${}"
}

set -add buffer snippets 'inlinemath' 'mk' %{
  phantom-selection-clear
  snippets-insert "$$${}$$${}"
  phantom-selection-add-selection
  phantom-selection-iterate-next
}

set -add buffer snippets 'inlinemathafter' '(\$[^\n]+\$)(.)' %{
 eval %sh{
   case "$kak_main_reg_2" in
     ,|\.|\?|-|" ") printf '%s\n' "snippets-insert \"${kak_main_reg_1}${kak_main_reg_2}\${}\"" ;;
     *) printf '%s\n' "snippets-insert \"${kak_main_reg_1} ${kak_main_reg_2}\${}\"" ;;
   esac
 }
}
