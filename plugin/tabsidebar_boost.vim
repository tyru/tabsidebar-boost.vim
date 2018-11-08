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

if get(g:, 'tabsidebar_boost#auto_adjust_tabsidebarcolumns', 0)
  augroup tabsidebar_boost
    autocmd!
    autocmd WinEnter,WinLeave,TabEnter,TabLeave,BufWinEnter,BufWinLeave,BufAdd,BufFilePost *
    \       call tabsidebar_boost#adjust_columns()
  augroup END
endif

nnoremap <silent> <Plug>(tabsidebar-boost-jump)            :<C-u>call tabsidebar_boost#jump()<CR>
nnoremap <silent> <Plug>(tabsidebar-boost-next-window)     :<C-u>call tabsidebar_boost#next_window()<CR>
nnoremap <silent> <Plug>(tabsidebar-boost-previous-window) :<C-u>call tabsidebar_boost#prev_window()<CR>


let &cpo = s:save_cpo
