if (exists("g:loaded_textobj_word_column"))
  finish
endif

function! TextObjWordBasedColumn(textobj)
  let cursor_col = col(".")
  exec "silent normal! v" . a:textobj . "\<Esc>"
  let start_col    = col("'<")
  let stop_col     = col("'>")
  let line_num     = line(".")
  let indent_level = s:indent_levell(".")
  let start_line   = s:find_boundary_row(line_num, start_col, indent_level, -1)
  let stop_line    = s:find_boundary_row(line_num, start_col, indent_level, 1)
  if (exists("g:textobj_word_column_no_smart_boundary_cols"))
    let col_bounds = [start_col, stop_col]
  else
    let col_bounds = s:find_smart_boundary_cols(start_line, stop_line, cursor_col, a:textobj)
  endif
  exec "keepjumps silent normal!" . start_line . "gg" . col_bounds[0] . "|" stop_line . "gg" . col_bounds[1] . "|"
endfunction

function! s:find_smart_boundary_cols(start_line, stop_line, cursor_col, textobj)
  let col_bounds = []
  let index      = a:start_line

  while index <= a:stop_line
    exec "keepjumps silent normal!" index . "gg" . a:cursor_col . "|v" . a:textobj . "\<Esc>"
    let start_col = col("'<")
    let stop_col  = col("'>")

    if index == a:start_line
      let col_bounds = [start_col, stop_col]
    else
      if start_col < col_bounds[0]
        let col_bounds[0] = start_col
      endif
      if stop_col > col_bounds[1]
        let col_bounds[1] = stop_col
      endif
    endif

    let index = index + 1
  endwhile

  return col_bounds
endfunction

function! s:find_boundary_row(line_num, start_col, indent_level, step)
  let non_blank       = getline(a:line_num + a:step) =~ "[^ \t]"
  let same_indent     = s:indent_levell(a:line_num + a:step) == a:indent_level
  let is_not_comment = ! s:is_comment(a:line_num + a:step, a:start_col)
  if same_indent && non_blank && is_not_comment
    return s:find_boundary_row(a:line_num + a:step, a:start_col, a:indent_level, a:step)
  else
    return a:line_num
  endif
endfunction

function! s:indent_levell(line_num)
  let line = getline(a:line_num)
  return match(line, "[^ \t]")
endfunction

function! s:is_comment(line_num, column)
  return synIDattr(synIDtrans(synID(a:line_num, a:column, 1)),"name") == "Comment"
endfunction

if (!exists("g:skip_default_textobj_word_column_mappings"))
  nnoremap <silent> vac :call TextObjWordBasedColumn("aw")<cr>
  nnoremap <silent> vaC :call TextObjWordBasedColumn("aW")<cr>
  nnoremap <silent> vic :call TextObjWordBasedColumn("iw")<cr>
  nnoremap <silent> viC :call TextObjWordBasedColumn("iW")<cr>

  onoremap <silent> ac :call TextObjWordBasedColumn("aw")<cr>
  onoremap <silent> aC :call TextObjWordBasedColumn("aW")<cr>
  onoremap <silent> ic :call TextObjWordBasedColumn("iw")<cr>
  onoremap <silent> iC :call TextObjWordBasedColumn("iW")<cr>
endif

let g:loaded_textobj_word_column = 1
