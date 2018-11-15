scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:has_tabsidebar = has('tabsidebar')

function! s:enabled() abort
  return s:has_tabsidebar && &showtabsidebar !=# 0
endfunction

function! s:get_chars(default) abort
  if type(get(g:, 'tabsidebar_boost#chars')) !=# v:t_string
    return a:default
  endif
  if stridx(g:tabsidebar_boost#chars, "\t") !=# -1
    echohl ErrorMsg
    echomsg 'tabsidebar-boost: g:tabsidebar_boost#chars cannot contain tab character.'
    \       'using default value...'
    echohl None
    return a:default
  endif
  return g:tabsidebar_boost#chars
endfunction

let g:tabsidebar_boost#chars = s:get_chars('asdfghjklzxcvbnmqwertyuiop')
let g:tabsidebar_boost#format_window = get(g:, 'tabsidebar_boost#format_window', 'tabsidebar_boost#format_window')
let g:tabsidebar_boost#format_tabpage = get(g:, 'tabsidebar_boost#format_tabpage', 'tabsidebar_boost#format_tabpage')


function! tabsidebar_boost#format_window(win) abort
  let w = getwininfo(win_getid(a:win.winnr))[0]
  let active = a:win.tabnr ==# tabpagenr() && a:win.winnr ==# winnr() ? '>' : ' '
  let id = tabsidebar_boost#is_jumping() ? printf(' (%s)', a:win.char_id()) : ''
  let name = w.loclist ? '[Location List]' :
  \          w.quickfix ? '[Quickfix List]' :
  \          empty(bufname(a:win.bufnr)) ? printf('Buffer #%d', a:win.bufnr) :
  \          fnamemodify(bufname(a:win.bufnr), ':t')
  let flags = (!w.terminal && getbufvar(a:win.bufnr, '&modified') ? ['+'] : []) +
  \           (getbufvar(a:win.bufnr, '&readonly') ? ['RO'] : [])
  let flags_status = empty(flags) ? '' : ' [' . join(flags, ',') . ']'
  return printf(' %s%s %s%s', active, id, name, flags_status)
endfunction

function! tabsidebar_boost#format_tabpage(tabnr, winlines) abort
  let title = gettabvar(a:tabnr, 'tabsidebar_boost_title')
  if title ==# ''
    let title = printf('Tab #%d', a:tabnr)
  endif
  return join([title] + a:winlines, "\n")
endfunction

function! tabsidebar_boost#set_tab_title(title) abort
  let t:tabsidebar_boost_title = a:title
  call tabsidebar_boost#adjust_column()
endfunction

function! tabsidebar_boost#tabsidebar(tabnr) abort
  if !s:enabled()
    return ''
  endif
  let wininfo = s:get_wininfo(g:tabsidebar_boost#chars)
  let winlines = map(tabpagebuflist(a:tabnr), {winidx,bufnr ->
  \ call(g:tabsidebar_boost#format_window, [
  \   s:find_window(wininfo, {'tabnr': a:tabnr, 'winnr': winidx + 1})
  \ ])
  \})
  return call(g:tabsidebar_boost#format_tabpage, [a:tabnr, winlines])
endfunction

function! tabsidebar_boost#adjust_column() abort
  if !s:enabled()
    return ''
  endif
  let &tabsidebarcolumns = tabsidebar_boost#get_max_column()
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

function! tabsidebar_boost#is_jumping() abort
  return s:is_jumping
endfunction

let s:is_jumping = 0

function! tabsidebar_boost#jump() abort
  if !s:enabled()
    return
  endif
  let wininfo = s:get_wininfo(g:tabsidebar_boost#chars)
  let wins = s:search_windows(wininfo, {})
  let buf = ''
  let s:is_jumping = 1
  " Input characters until matching exactly or failing to match.
  try
    if get(g:, 'tabsidebar_boost#auto_adjust_tabsidebarcolumns')
      let &tabsidebarcolumns = tabsidebar_boost#get_max_column()
    endif
    redraw
    while 1
      echon "\rInput window character(s): " . buf
      let c = s:getchar()
      if c ==# "\<Esc>"
        redraw
        echo ''
        return
      endif
      let buf .= c
      if empty(filter(copy(wins), {_,w -> w.char_id() !=# buf && w.char_id() =~# '^' . buf }))
        break
      endif
    endwhile
  finally
    let s:is_jumping = 0
  endtry
  let win = get(filter(copy(wins), {_,w -> w.char_id() ==# buf }), 0, {})
  if empty(win)
    return
  endif
  call win_gotoid(win_getid(win.winnr, win.tabnr))
endfunction

function! tabsidebar_boost#next_window() abort
  return s:next_window(v:count1, g:tabsidebar_boost#chars)
endfunction

function! tabsidebar_boost#previous_window() abort
  return s:next_window(-v:count1, g:tabsidebar_boost#chars)
endfunction

function! s:next_window(n, chars) abort
  if !s:enabled()
    return
  endif
  let [wins, curidx] = s:get_windows_with_index(a:chars)
  if curidx ==# -1
    throw 'tabsidebar-boost: could not find current window'
  endif
  let win = wins[(curidx + a:n) % len(wins)]
  call win_gotoid(win_getid(win.winnr, win.tabnr))
endfunction

function! s:get_windows_with_index(chars) abort
  let wininfo = s:get_wininfo(a:chars)
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

function! s:get_wininfo(chars) abort
  let wininfo = {'__chars__': a:chars}
  let id = 0
  for tabnr in range(1, tabpagenr('$'))
    let winnr = 1
    for bufnr in tabpagebuflist(tabnr)
      let wininfo[join([id, tabnr, bufnr, winnr], "\t")] = 1
      let winnr += 1
      let id += 1
    endfor
  endfor
  let wininfo.__count__ = id
  return wininfo
endfunction

function! s:find_window(wininfo, conditions) abort
  return get(s:search_windows(a:wininfo, a:conditions), 0, {})
endfunction

function! s:search_windows(wininfo, conditions) abort
  let re = '^' . get(a:conditions, 'id', '[^\t]\+')
  \     . '\t' . get(a:conditions, 'tabnr', '[^\t]\+')
  \     . '\t' . get(a:conditions, 'bufnr', '[^\t]\+')
  \     . '\t' . get(a:conditions, 'winnr', '[^\t]\+')
  \     . '$'
  let keys = filter(keys(a:wininfo), {_,key -> key =~# re})
  " Convert window strings to dictionary
  let wins = map(map(keys, {_,k -> split(k, '\t')}), {_,items -> {
  \ 'id': items[0] + 0,
  \ 'char_id': function('s:convert_id', [items[0] + 0, a:wininfo]),
  \ 'tabnr': items[1] + 0,
  \ 'bufnr': items[2] + 0,
  \ 'winnr': items[3] + 0,
  \}})
  return type(get(a:conditions, 'order_by')) ==# v:t_func ?
  \         sort(wins, a:conditions.order_by) : wins
endfunction

function! s:convert_id(n, wininfo) abort
  let chars = a:wininfo.__chars__
  let base = len(chars)
  let max_n = a:wininfo.__count__
  let digit = max_n <=# 0 ? 1 : float2nr(floor(log(max_n) / log(base) + 1))
  let n = a:n
  let id = ''
  for _ in range(digit)
    let id = chars[n % base] . id
    let n = n / base
  endfor
  return id
endfunction

let &cpo = s:save_cpo
