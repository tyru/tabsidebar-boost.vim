scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let g:tabsidebar_boost#format_window = get(g:, 'tabsidebar_boost#format_window', 'tabsidebar_boost#format_window')
let g:tabsidebar_boost#format_tabpage = get(g:, 'tabsidebar_boost#format_tabpage', 'tabsidebar_boost#format_tabpage')


function! tabsidebar_boost#format_window(win) abort
  let active = a:win.tabnr ==# tabpagenr() && a:win.winnr ==# winnr() ? '*' : ' '
  let modified = getbufvar(a:win.bufnr, '&modified') ? ['+'] : []
  let readonly = getbufvar(a:win.bufnr, '&readonly') ? ['RO'] : []
  let flags = modified + readonly
  let flags_status = empty(flags) ? '' : ' [' . join(flags, ',') . ']'
  let name = empty(bufname(a:win.bufnr)) ? '[No Name]' : fnamemodify(bufname(a:win.bufnr), ':t')
  return printf(' %s%s (%s) %s', active, flags_status, a:win.bufnr, name)
endfunction

function! tabsidebar_boost#format_tabpage(tabnr, winlines) abort
  return join([a:tabnr] + a:winlines, "\n")
endfunction

function! tabsidebar_boost#tabsidebar(tabnr) abort
  if !has('tabsidebar')
    return ''
  endif
  let wininfo = s:get_wininfo()
  let winlines = map(tabpagebuflist(a:tabnr), {winidx,bufnr ->
  \ call(g:tabsidebar_boost#format_window, [
  \   s:find_window(wininfo, {'tabnr': a:tabnr, 'winnr': winidx + 1})
  \ ])
  \})
  return call(g:tabsidebar_boost#format_tabpage, [a:tabnr, winlines])
endfunction

function! tabsidebar_boost#get_max_column() abort
  let maxcol = 0
  for tabnr in range(1, tabpagenr('$'))
    for line in split(tabsidebar_boost#tabsidebar(tabnr), '\n')
      let maxcol = max([len(line), maxcol])
    endfor
  endfor
  return maxcol
endfunction

function! tabsidebar_boost#jump() abort
  if !has('tabsidebar')
    return
  endif
  let wininfo = s:get_wininfo()
  let wins = s:search_windows(wininfo, {})
  let buf = ''
  " Input characters until matching exactly or failing to match.
  while 1
    echon "\rInput window character(s): " . buf
    let c = s:getchar()
    if c ==# "\<Esc>"
      return
    endif
    if c ==# "\<CR>"
      break
    endif
    let buf .= c
    if empty(filter(copy(wins), {_,w -> w.bufnr !=# buf && w.bufnr =~# '^' . buf }))
      break
    endif
  endwhile
  let win = get(filter(copy(wins), {_,w -> w.bufnr ==# buf }), 0, {})
  if empty(win)
    echohl WarningMsg
    echomsg 'no such window:' buf
    echohl None
    return
  endif
  call win_gotoid(win_getid(win.winnr, win.tabnr))
endfunction

function! tabsidebar_boost#next_window() abort
  if !has('tabsidebar')
    return
  endif
  let [wins, curidx] = s:get_windows_with_index()
  if curidx ==# -1
    throw 'tabsidebar-boost: could not find current window'
  endif
  if curidx + 1 >= len(wins)
    let win = wins[0]
  else
    let win = wins[curidx + 1]
  endif
  call win_gotoid(win_getid(win.winnr, win.tabnr))
endfunction

function! tabsidebar_boost#prev_window() abort
  if !has('tabsidebar')
    return
  endif
  let [wins, curidx] = s:get_windows_with_index()
  if curidx ==# -1
    throw 'tabsidebar-boost: could not find current window'
  endif
  if curidx - 1 < 0
    let win = wins[len(wins) - 1]
  else
    let win = wins[curidx - 1]
  endif
  call win_gotoid(win_getid(win.winnr, win.tabnr))
endfunction

function! s:get_windows_with_index() abort
  let wininfo = s:get_wininfo()
  let wins = s:search_windows(wininfo, {'order_by': function('s:by_tabnr_and_winnr')})
  let curidx = -1
  for i in range(len(wins))
    if wins[i].tabnr ==# tabpagenr() && wins[i].winnr ==# winnr()
      let curidx = i
      break
    endif
  endfor
  return [wins, curidx]
endfunction

function! s:by_tabnr_and_winnr(a, b) abort
  if a:a.tabnr !=# a:b.tabnr
    return s:asc(a:a.tabnr, a:b.tabnr)
  endif
  return s:asc(a:a.winnr, a:b.winnr)
endfunction

function! s:asc(a, b) abort
    return a:a > a:b ? 1 : a:a < a:b ? -1 : 0
endfunction

function! s:getchar(...) abort
  let c = call('getchar', a:000)
  return type(c) is# v:t_number ? nr2char(c) : c
endfunction

function! s:get_wininfo() abort
  let wininfo = {}
  for tabnr in range(1, tabpagenr('$'))
    let winnr = 1
    for bufnr in tabpagebuflist(tabnr)
      let wininfo[join([tabnr, bufnr, winnr], "\t")] = 1
      let winnr += 1
    endfor
  endfor
  return wininfo
endfunction

function! s:find_window(wininfo, conditions) abort
  return get(s:search_windows(a:wininfo, a:conditions), 0, {})
endfunction

function! s:search_windows(wininfo, conditions) abort
  let re = '^' . get(a:conditions, 'tabnr', '[^\t]\+')
  \     . '\t' . get(a:conditions, 'bufnr', '[^\t]\+')
  \     . '\t' . get(a:conditions, 'winnr', '[^\t]\+')
  \     . '$'
  let keys = filter(keys(a:wininfo), {_,key -> key =~# re})
  " Convert window strings to dictionary
  let wins = map(map(keys, {_,k -> split(k, '\t')}), {_,items -> {
  \ 'tabnr': items[0] + 0,
  \ 'bufnr': items[1] + 0,
  \ 'winnr': items[2] + 0,
  \}})
  return type(get(a:conditions, 'order_by')) ==# v:t_func ?
  \         sort(wins, a:conditions.order_by) : wins
endfunction

let &cpo = s:save_cpo
