echo "sourced snippets"

set buffer snippets_auto_expand 'true'
map buffer normal <a-f> ": phantom-selection-iterate-next<ret>"
map buffer normal <a-F> ": phantom-selection-iterate-prev<ret>"
map buffer insert <a-f> "<esc>: try phantom-selection-iterate-next<ret>i"
map buffer insert <a-F> "<esc>: try phantom-selection-iterate-prev<ret>i"

set buffer snippets 'breakpoint' ';b' %{
  snippets-insert %@breakpoint()${}@
}
