function reorder_buffers#shift(direction)
  let buffers = s:visible_buffers()
  let current_buffer = winbufnr(0)
  let current_index = index(buffers, current_buffer)

  " Guard
  if len(buffers) <=1
    return
  elseif s:has_modified_buffers(buffers) && !s:auto_save_buffers()
    echo "Buffers must be saved first"
    return
  end

  " Grab buffers to delete
  let at_beginning = current_index == 0 && a:direction == "left"
  let at_end = current_index == len(buffers)-1 && a:direction == "right"
  let [buffers_before, buffers_after] = s:split_array_at(buffers, current_buffer)
  if a:direction == "left"
    if at_beginning
      let buffers_to_delete = [current_buffer]
      let restore_index = len(buffers) - 1
    else
      let buffers_to_delete = [buffers_before[-1]] + buffers_after
      let restore_index = current_index - 1
    end
  else
    if at_end
      let buffers_to_delete = buffers[:-2]
      let restore_index = 0
    else
      let buffers_to_delete = [current_buffer] + buffers_after[1:]
      let restore_index = current_index + 1
    end
  end

  " Wipe required buffers then restore them
  let restore_state = s:buffer_reopen_states(buffers_to_delete)
  execute("bwipeout ". join(buffers_to_delete))
  for state in restore_state
    execute("edit +". state["linenr"] ." ". state["path"])
  endfor

  " Re-select the current buffer
  execute("buffer ". s:visible_buffers()[restore_index])
endfunction

function s:auto_save_buffers()
  let allow_auto_save = get(g:, 'reorder_buffers_allow_auto_save', v:false)
  if allow_auto_save == v:true
    silent bufdo :w
    return v:true
  end
  return v:false
endfunction

function s:visible_buffers()
  return range(1,bufnr('$'))->filter(funcref("s:is_visible_buffer"))
endfunction

function s:is_visible_buffer(index, buffnr)
  return buflisted(a:buffnr) && getbufvar(a:buffnr, "&buftype") != "quickfix"
endfunction

function s:has_modified_buffers(buffers)
  let modified_buffers = copy(a:buffers)->filter({_, buffnr -> getbufvar(buffnr, "&modified") == v:true })
  return len(modified_buffers) > 0
endfunction

function s:split_array_at(array, item)
  let idx = index(a:array, a:item)
  let before = a:array[:min([max([0, idx - 1]), idx])]
  let after = a:array[idx + 1:]
  return [before, after]
endfunction

function s:buffer_reopen_states(buffers)
  let cursor_positions = s:buffer_line_numbers()
  return copy(a:buffers)->map({_, buffnr -> #{
    \  linenr: cursor_positions[buffnr],
    \  path: expand("#".buffnr.":%")
    \  }})
endfunction

function s:buffer_line_numbers()
  let cursor_positions = {}
  for info in getbufinfo()
    let cursor_positions[info["bufnr"]] = info["lnum"]
  endfor
  return cursor_positions
endfunction
