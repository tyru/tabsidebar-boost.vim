
function! tabsidebar_boost#tabsidebar(tabnr) abort
  if !has('tabsidebar')
    return ''
  endif
  let wininfo = s:assign_ids_to_windows(g:tabsidebar_boost#chars)
  let wins = map(tabpagebuflist(a:tabnr), {winidx,bufnr ->
  \ printf('  %s %s) %s',
  \ a:tabnr ==# tabpagenr() && winidx ==# winnr() - 1 ? '*' : ' ',
  \ s:find_window(wininfo, {'tabnr': a:tabnr, 'winnr': winidx + 1}).id,
  \ empty(bufname(bufnr)) ? '[No Name]' : fnamemodify(bufname(bufnr), ':t'))
  \})
  return join([a:tabnr] + wins, "\n")
endfunction

function! tabsidebar_boost#jump() abort
  if !has('tabsidebar')
    return
  endif
  let wininfo = s:assign_ids_to_windows(g:tabsidebar_boost#chars)
  let wins = s:search_windows(wininfo, {})
  let buf = ''
  " Input characters until matching exactly or failing to match.
  while 1
    echon "\rInput window character(s): " . buf
    let buf .= s:getchar()
    if empty(filter(copy(wins), {_,w -> w.id !=# buf && w.id =~# '^' . buf }))
      break
    endif
  endwhile
  let win = get(filter(copy(wins), {_,w -> w.id ==# buf }), 0, {})
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
  let [wins, curidx] = s:get_windows_with_index(g:tabsidebar_boost#chars)
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
  let [wins, curidx] = s:get_windows_with_index(g:tabsidebar_boost#chars)
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

function! s:get_windows_with_index(chars) abort
  let wininfo = s:assign_ids_to_windows(a:chars)
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

function! s:assign_ids_to_windows(chars) abort
  let pairs = []
  for tabnr in range(1, tabpagenr('$'))
    let winnr = 1
    for bufnr in tabpagebuflist(tabnr)
      call add(pairs, [tabnr, bufnr, winnr])
      let winnr += 1
    endfor
  endfor
  let wininfo = {}
  let base = len(a:chars)
  let digit = len(pairs) <=# 1 ? 1 : float2nr(floor(log(len(pairs) - 1) / log(base) + 1))
  for i in range(len(pairs))
    let id = ''
    let n = i
    for _ in range(digit)
      let id = a:chars[n % base] . id
      let n = n / base
    endfor
    let [tabnr, bufnr, winnr] = pairs[i]
    let key = join([id, tabnr, bufnr, winnr], "\t")
    let wininfo[key] = 1
  endfor
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
  \ 'id': items[0],
  \ 'tabnr': items[1] + 0,
  \ 'bufnr': items[2] + 0,
  \ 'winnr': items[3] + 0,
  \}})
  return type(get(a:conditions, 'order_by')) ==# v:t_func ?
  \         sort(wins, a:conditions.order_by) : wins
endfunction
