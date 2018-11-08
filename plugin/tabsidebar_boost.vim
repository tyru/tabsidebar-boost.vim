scriptencoding utf-8
if exists('g:loaded_tabsidebar_boost')
  finish
endif
let g:loaded_tabsidebar_boost = 1
let s:save_cpo = &cpo
set cpo&vim

if !has('tabsidebar')
  echohl ErrorMsg
  echomsg 'tabsidebar-boost: this plugin requires tabsidebar patch: https://rbtnn.github.io/vim/'
  echohl None
  finish
endif


nnoremap <silent> <Plug>(tabsidebar-boost-jump)            :<C-u>call tabsidebar_boost#jump()<CR>
nnoremap <silent> <Plug>(tabsidebar-boost-next-window)     :<C-u>call tabsidebar_boost#next_window()<CR>
nnoremap <silent> <Plug>(tabsidebar-boost-previous-window) :<C-u>call tabsidebar_boost#prev_window()<CR>

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


let &cpo = s:save_cpo
