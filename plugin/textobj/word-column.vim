if (exists("g:loaded_textobj_word_column"))
  finish
endif

function! TextObjWordBasedColumn(textobj)
  let cursor_col = col(".")
  exec "silent normal! v" . a:textobj . "\<Esc>"
  let start_col       = col("'<")
  let stop_col        = col("'>")
  let line_num        = line(".")
  let indent_level    = s:indent_levell(".")
  let start_line      = s:find_boundary_row(line_num, start_col, indent_level, -1)
  let stop_line       = s:find_boundary_row(line_num, start_col, indent_level, 1)
  let whitespace_only = s:whitespace_column_wanted(start_line, stop_line, cursor_col)

  if (exists("g:textobj_word_column_no_smart_boundary_cols"))
    let col_bounds = [start_col, stop_col]
  else
    let col_bounds = s:find_smart_boundary_cols(start_line, stop_line, cursor_col, a:textobj, whitespace_only)
  endif

  exec "keepjumps silent normal!" . start_line . "gg" . col_bounds[0] . "|" stop_line . "gg" . col_bounds[1] . "|"
endfunction

function! s:find_smart_boundary_cols(start_line, stop_line, cursor_col, textobj, whitespace_only)
  let col_bounds = []
  let index      = a:start_line
  if a:whitespace_only
    let word_start = ""
    let s:col_bounds_fn = function("s:col_bounds_min")
  else
    let word_start = "lb"
    let s:col_bounds_fn = function("s:col_bounds_max")
  endif

  while index <= a:stop_line
    exec "keepjumps silent normal!" index . "gg" . a:cursor_col . "|" . word_start . "v" . a:textobj . "\<Esc>"
    let start_col  = col("'<")
    let stop_col   = col("'>")
    let col_bounds = s:col_bounds_fn(start_col, stop_col, col_bounds)
    let index      = index + 1
  endwhile

  return col_bounds
endfunction

function! s:col_bounds_max(start_col, stop_col, col_bounds)
  if a:col_bounds == []
    return [a:start_col, a:stop_col]
  endif
  if a:start_col < a:col_bounds[0]
    let a:col_bounds[0] = a:start_col
  endif
  if a:stop_col > a:col_bounds[1]
    let a:col_bounds[1] = a:stop_col
  endif
  return a:col_bounds
endfunction

function! s:col_bounds_min(start_col, stop_col, col_bounds)
  if a:col_bounds == []
    return [a:start_col, a:stop_col]
  endif
  if a:start_col > a:col_bounds[0]
    let a:col_bounds[0] = a:start_col
  endif
  if a:stop_col < a:col_bounds[1]
    let a:col_bounds[1] = a:stop_col
  endif
  return a:col_bounds
endfunction

function! s:whitespace_column_wanted(start_line, stop_line, cursor_col)
  let index = a:start_line
  while index <= a:stop_line
    let char = getline(index)[a:cursor_col - 1]
    if char != " " && char != "\t"
      return 0
    end
    let index = index + 1
  endwhile
  return 1
endfunction

function! s:find_boundary_row(line_num, start_col, indent_level, step)
  let non_blank      = getline(a:line_num + a:step) =~ "[^ \t]"
  let same_indent    = s:indent_levell(a:line_num + a:step) == a:indent_level
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
  onoremap <silent> ac  :call TextObjWordBasedColumn("aw")<cr>
  onoremap <silent> aC  :call TextObjWordBasedColumn("aW")<cr>
  onoremap <silent> ic  :call TextObjWordBasedColumn("iw")<cr>
  onoremap <silent> iC  :call TextObjWordBasedColumn("iW")<cr>
endif

let g:loaded_textobj_word_column = 1
