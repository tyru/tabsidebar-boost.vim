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
    for event in [
    \ 'WinEnter',
    \ 'WinLeave',
    \ 'TabEnter',
    \ 'TabLeave',
    \ 'BufWinEnter',
    \ 'BufWinLeave',
    \ 'TerminalOpen',
    \ 'BufAdd',
    \ 'BufFilePost',
    \ 'BufWritePost',
    \ 'TextChanged',
    \ 'TextChangedI',
    \]
      execute 'autocmd' event '* call tabsidebar_boost#adjust_column()'
    endfor
  augroup END
endif

nnoremap <silent> <Plug>(tabsidebar-boost-jump)            :<C-u>call tabsidebar_boost#jump()<CR>
nnoremap <silent> <Plug>(tabsidebar-boost-next-window)     :<C-u>call tabsidebar_boost#next_window()<CR>
nnoremap <silent> <Plug>(tabsidebar-boost-previous-window) :<C-u>call tabsidebar_boost#previous_window()<CR>

command! -bar -nargs=* TabSideBarBoostSetTitle
\         call tabsidebar_boost#set_tab_title(<q-args>)
command! -bar TabSideBarBoostRestore :


let &cpo = s:save_cpo
