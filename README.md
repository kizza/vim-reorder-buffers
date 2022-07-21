# Reorder your vim buffers!
[![Tests](https://github.com/kizza/vim-reorder-buffers/actions/workflows/tests.yml/badge.svg)](https://github.com/kizza/vim-reorder-buffers/actions/workflows/tests.yml)

The vim buffer list is immutable - and there's lots of context to how and why.  Ultimately however there are numerous reasons where you want to move them around.

This plugin achieves reordering while adhering to the immutability - specifically it quite literally closes buffers and re-opens them in such a way as to be seamless (pretty much) for most use cases.


## How to use it

The plugin provides two commands `:ShiftBufferLeft` and `:ShiftBufferRight`. These two do essentially what you expect.

**Bindings**

For the best experience you may wish to add some bindings to call these.  I find that _leaning into_ the natural `gt` and `gT` tab navigation works well (with a prefixed `<leader>`)

```vim
nnoremap <silent><leader>gT :ShiftBufferLeft<CR>
nnoremap <silent><leader>gt :ShiftBufferRight<CR>
```

**Auto-saving buffers**

Given the plugin closes buffers to reopen them... unsaved buffers present a problem.  By default the plugin will warn (and do nothing) if there are unsaved buffers, or you can set the following to auto-save them by default.

```
let g:reorder_buffers_allow_auto_save = v:true
```
