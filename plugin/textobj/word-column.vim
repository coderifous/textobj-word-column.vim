if (exists("g:loaded_textobj_word_column"))
  finish
endif

function! TextObjWordBasedColumn()
  let startcol    = col("'<")
  let stopcol     = col("'>")
  let linenum     = line(".")
  let indentlevel = s:indent_level(".")
  let startline   = s:find_boundary_row(linenum, startcol, indentlevel, -1)
  let stopline    = s:find_boundary_row(linenum, startcol, indentlevel, 1)
  exec "silent normal!" startline . "gg" . startcol . "|" stopline . "gg" . stopcol . "|"
endfunction

function! s:find_boundary_row(linenum, startcol, indentlevel, step)
  let nonblank       = getline(a:linenum + a:step) =~ "[^ \t]"
  let sameindent     = s:indent_level(a:linenum + a:step) == a:indentlevel
  let is_not_comment = ! s:is_comment(a:linenum + a:step, a:startcol)
  if sameindent && nonblank && is_not_comment
    return s:find_boundary_row(a:linenum + a:step, a:startcol, a:indentlevel, a:step)
  else
    return a:linenum
  endif
endfunction

function! s:indent_level(linenum)
  let line = getline(a:linenum)
  return match(line, "[^ \t]")
endfunction

function! s:is_comment(linenum, column)
  return synIDattr(synIDtrans(synID(a:linenum, a:column, 1)),"name") == "Comment"
endfunction

if (!exists("g:skip_default_textobj_word_column_mappings"))
  vnoremap <silent> ac <Esc>vaw:call TextObjWordBasedColumn()<cr>
  vnoremap <silent> aC <Esc>vaW:call TextObjWordBasedColumn()<cr>
  vnoremap <silent> ic <Esc>viw:call TextObjWordBasedColumn()<cr>
  vnoremap <silent> iC <Esc>viW:call TextObjWordBasedColumn()<cr>
  onoremap <silent> ac :normal vac<cr>
  onoremap <silent> aC :normal vaC<cr>
  onoremap <silent> ic :normal vic<cr>
  onoremap <silent> iC :normal viC<cr>
endif

let g:loaded_textobj_word_column = 1
