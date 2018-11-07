# Tabsidebar-Boost

Make Vim-TabSideBar more useful! (see http://rbtnn.github.io/vim/ for Vim-TabSideBar patch)

# Configuration (example)

```vim
nmap <C-n>           <Plug>(tabsidebar-boost-next-window)
nmap <C-p>           <Plug>(tabsidebar-boost-previous-window)
nmap <Space><Space>  <Plug>(tabsidebar-boost-jump)

let &g:tabsidebar = '%!tabsidebar_boost#tabsidebar(g:actual_curtabpage)'
```

`<Plug>(tabsidebar-boost-next-window)` and `<Plug>(tabsidebar-boost-previous-window)` jumps to the next / previous window across tab page.
`<Plug>(tabsidebar-boost-jump)` shows prompt, and if you enter character(s) of a window, it jumps to the specified window quickly.

# Demo

![demo](demo.gif)
