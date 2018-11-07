scriptencoding utf-8
if exists('g:loaded_tabsidebar_boost')
  finish
endif
let g:loaded_tabsidebar_boost = 1
let s:save_cpo = &cpo
set cpo&vim


nnoremap <silent> <Plug>(tabsidebar-boost-jump)            :<C-u>call tabsidebar_boost#jump()<CR>
nnoremap <silent> <Plug>(tabsidebar-boost-next-window)     :<C-u>call tabsidebar_boost#next_window()<CR>
nnoremap <silent> <Plug>(tabsidebar-boost-previous-window) :<C-u>call tabsidebar_boost#prev_window()<CR>

let g:tabsidebar_boost#chars = 'asdfghjklzxcvbnmqwertyuiop'


let &cpo = s:save_cpo
