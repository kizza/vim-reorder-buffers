function reorder_buffers#shift(direction)
  let buffers = s:visible_buffers()
  let current_index = index(buffers, winbufnr(0))
  let target = a:direction == "left" ? current_index - 1 : current_index + 1
  let target = target < 0 ? len(buffers) - 1 : target >= len(buffers) ? 0 : target
  call s:move_buffer_to_index(buffers, current_index, target)
endfunction

function reorder_buffers#move_to(position)
  let buffers = s:visible_buffers()
  let current_index = index(buffers, winbufnr(0))
  let target = s:clamp_position(a:position, buffers)
  call s:move_buffer_to_index(buffers, current_index, target)
endfunction

" Close all buffers after the given 1-based position (or current buffer)
function reorder_buffers#close_after(...)
  let buffers = s:visible_buffers()
  let idx = a:0 ? s:clamp_position(a:1, buffers) : index(buffers, winbufnr(0))
  call s:close_buffers(buffers, buffers[idx + 1:])
endfunction

" Close all buffers before the given 1-based position (or current buffer)
function reorder_buffers#close_until(...)
  let buffers = s:visible_buffers()
  let idx = a:0 ? s:clamp_position(a:1, buffers) : index(buffers, winbufnr(0))
  call s:close_buffers(buffers, buffers[:idx - 1])
endfunction

" Core: close a set of buffers, switching to a remaining buffer first
function s:close_buffers(buffers, buffers_to_close)
  if empty(a:buffers_to_close)
    return
  elseif s:has_modified_buffers(a:buffers_to_close) && !s:auto_save_buffers()
    echo "Buffers must be saved first"
    return
  end

  " If current buffer is being closed, switch to the nearest remaining buffer
  let current_buffer = winbufnr(0)
  if index(a:buffers_to_close, current_buffer) >= 0
    let remaining = copy(a:buffers)->filter({_, nr -> index(a:buffers_to_close, nr) < 0})
    if empty(remaining)
      echo "Cannot close all buffers"
      return
    end
    execute("buffer ". remaining[0])
  end

  execute("bwipeout ". join(a:buffers_to_close))
  doautocmd BufEnter
endfunction

" Core: move the buffer at current_index to target index by wiping and
" re-opening the minimal set of buffers required to achieve the new order.
function s:move_buffer_to_index(buffers, current_index, target)
  if len(a:buffers) <= 1 || a:current_index == a:target
    return
  elseif s:has_modified_buffers(a:buffers) && !s:auto_save_buffers()
    echo "Buffers must be saved first"
    return
  end

  " Build desired order
  let desired = copy(a:buffers)
  call remove(desired, a:current_index)
  call insert(desired, a:buffers[a:current_index], a:target)

  " Wipe and re-open buffers from the first changed position onward
  let first_changed = min([a:current_index, a:target])
  let buffers_to_reopen = desired[first_changed:]
  let restore_state = s:buffer_reopen_states(buffers_to_reopen)
  execute("bwipeout ". join(buffers_to_reopen))
  for state in restore_state
    execute("edit +". state["linenr"] ." ". state["path"])
  endfor

  execute("buffer ". s:visible_buffers()[a:target])
endfunction

" Helpers

" Convert a 1-based position to a 0-based index, clamped to valid range
function s:clamp_position(position, buffers)
  return max([0, min([a:position - 1, len(a:buffers) - 1])])
endfunction

function s:auto_save_buffers()
  if get(g:, 'reorder_buffers_allow_auto_save', v:false) == v:true
    silent bufdo :w
    return v:true
  end
  return v:false
endfunction

function s:visible_buffers()
  return range(1, bufnr('$'))->filter({_, nr -> buflisted(nr) && getbufvar(nr, "&buftype") != "quickfix"})
endfunction

function s:has_modified_buffers(buffers)
  return len(copy(a:buffers)->filter({_, nr -> getbufvar(nr, "&modified") == v:true})) > 0
endfunction

function s:buffer_reopen_states(buffers)
  let positions = s:buffer_line_numbers()
  return copy(a:buffers)->map({_, nr -> #{ linenr: positions[nr], path: expand("#".nr.":%") }})
endfunction

function s:buffer_line_numbers()
  let result = {}
  for info in getbufinfo()
    let result[info["bufnr"]] = info["lnum"]
  endfor
  return result
endfunction
