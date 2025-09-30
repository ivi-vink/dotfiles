echo "sourced snippets"

map buffer normal <a-f> ": phantom-selection-iterate-next<ret>"
map buffer normal <a-F> ": phantom-selection-iterate-prev<ret>"
map buffer insert <a-f> "<esc>: try phantom-selection-iterate-next<ret>i"
map buffer insert <a-F> "<esc>: try phantom-selection-iterate-prev<ret>i"

set buffer snippets 'frac1' '//' %{
  phantom-selection-clear
  snippets-insert %@\frac{ ${} }{ ${} } ${}@
  phantom-selection-add-selection
  phantom-selection-iterate-next
}
set -add buffer snippets 'frac2' %<((\d+)|(\d*)(\\)?([A-Za-z]+)((\^|_)(\{\d+\}|\d))*)/> %{
  phantom-selection-clear
  snippets-insert "\frac{ %reg{1} }{ ${} } ${}"
  phantom-selection-add-selection
  phantom-selection-iterate-next
}
set -add buffer snippets 'frac3' '([^\n]+\))/' %{
  phantom-selection-clear

  exec "i%reg{1}<esc>hm_"
  exec %{"sd}
  snippets-insert "\frac { %reg{s} }{ ${} } ${}"

  phantom-selection-add-selection
  phantom-selection-iterate-next
}
