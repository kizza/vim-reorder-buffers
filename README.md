# vim-reorder-buffers

[![Tests](https://github.com/kizza/vim-reorder-buffers/actions/workflows/tests.yml/badge.svg)](https://github.com/kizza/vim-reorder-buffers/actions/workflows/tests.yml)

Vim's buffer list is immutable — buffer numbers are assigned sequentially and can never be rearranged. This plugin works around that by strategically closing and re-opening buffers so they appear in the order you want. Cursor positions are preserved, and the whole thing is seamless enough that you'd never know it happened.

Built to pair with tabline plugins like [vim-buftabline](https://github.com/ap/vim-buftabline) where your buffers are displayed as a tab bar and their visual order actually matters.

![Example](https://raw.githubusercontent.com/kizza/vim-reorder-buffers/master/images/example.gif)

## Commands

All positions are **1-based**, matching what you see in your tabline.

| Command | Description |
|---|---|
| `:ShiftBufferLeft` | Move the current buffer one position to the left (wraps around) |
| `:ShiftBufferRight` | Move the current buffer one position to the right (wraps around) |
| `:MoveBufferTo {n}` | Move the current buffer to position `n` |
| `:CloseBuffersAfter {n}` | Close all buffers after position `n` |
| `:CloseBuffersUntil {n}` | Close all buffers before position `n` |

### Examples

Given buffers `| 1:A | 2:B | 3:C | 4:D | 5:E |` with `C` focused:

```
:ShiftBufferLeft       →  | 1:A | 2:C | 3:B | 4:D | 5:E |
:ShiftBufferRight      →  | 1:A | 2:B | 3:D | 4:C | 5:E |
:MoveBufferTo 1        →  | 1:C | 2:A | 3:B | 4:D | 5:E |
:CloseBuffersAfter 3   →  | 1:A | 2:B | 3:C |
:CloseBuffersUntil 3   →  | 1:C | 2:D | 3:E |
```

## Bindings

Leaning into the natural `gt` / `gT` tab navigation with a `<leader>` prefix works well:

```vim
nnoremap <silent><leader>gT :ShiftBufferLeft<CR>
nnoremap <silent><leader>gt :ShiftBufferRight<CR>
```

Jump to a specific position:

```vim
nnoremap <silent><leader>1 :MoveBufferTo 1<CR>
nnoremap <silent><leader>2 :MoveBufferTo 2<CR>
```

## Options

### Auto-saving buffers

The plugin closes buffers to reorder them, so unsaved changes are a problem. By default it will warn and do nothing. Set the following to auto-save before reordering:

```vim
let g:reorder_buffers_allow_auto_save = v:true
```

## Installation

Use your preferred plugin manager:

```vim
" vim-plug
Plug 'kizza/vim-reorder-buffers'

" packer.nvim
use 'kizza/vim-reorder-buffers'

" lazy.nvim
{ 'kizza/vim-reorder-buffers' }
```
