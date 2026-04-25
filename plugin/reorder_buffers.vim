if exists('g:loaded_reorder_buffers_loaded')
  finish
endif
let g:loaded_reorder_buffers_loaded = 1

" Options
" let g:reorder_buffers_allow_auto_save = v:true

" Mappings
command! ShiftBufferLeft call reorder_buffers#shift("left")
command! ShiftBufferRight call reorder_buffers#shift("right")
command! -nargs=1 MoveBufferTo call reorder_buffers#move_to(<args>)
command! -nargs=1 CloseBuffersAfter call reorder_buffers#close_after(<args>)
command! -nargs=1 CloseBuffersUntil call reorder_buffers#close_until(<args>)

