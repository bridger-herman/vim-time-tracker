let g:time_tracker_dir = expand('~/.vim/.time_tracker/')

function! GetRootGitRepo()
  let full_path = ''
  let git_dir = ''
  let path_arg = '%:p'
  while full_path != '/'
    let full_path = expand(path_arg)
    let listing = split(globpath(full_path, '.git'), '\n')
    if len(listing) > 0
      let git_dir = full_path
    endif
    let path_arg = path_arg . ':h'
  endwhile

  return substitute(git_dir, '/', '_', 'g')
endfunction

function! g:TimeTrackerClockIn()
  " Check if in a git repo - if so it's a project
  let tracker_name = GetRootGitRepo()
  if tracker_name == ''
    return
  endif

  let tracker_file = g:time_tracker_dir . tracker_name
  if !filereadable(tracker_file)
    if writefile([localtime()], tracker_file)
      execute '!mkdir -p ' . g:time_tracker_dir
      if writefile([localtime()], tracker_file)
        echom 'Still failed to write, shit'
      endif
    endif
    return
  endif

  let rows = readfile(tracker_file)
  if get(rows, len(rows) - 1) == ''
    if writefile(rows + [localtime()], tracker_file)
    endif
  else
    if writefile(rows + ['ignore'], tracker_file)
    endif
  endif
endfunction

function! g:TimeTrackerClockOut()
  " Check if in a git repo - if so it's a project
  let tracker_name = GetRootGitRepo()
  if tracker_name == ''
    return
  endif

  let tracker_file = g:time_tracker_dir . tracker_name
  if !filereadable(tracker_file)
    return
  endif
  let rows = readfile(tracker_file)
  if get(rows, len(rows) - 1) == 'ignore'
    if writefile(rows[:-2], tracker_file)
    endif
  else
    if writefile(rows + [localtime(), ''], tracker_file)
    endif
  endif
endfunction

function! g:TimeTrackerStatus()
  " Check if in a git repo - if so it's a project
  let tracker_name = GetRootGitRepo()
  if tracker_name == ''
    return
  endif

  let tracker_file = g:time_tracker_dir . tracker_name
  let rows = readfile(tracker_file)

  let sum = 0
  let previous_1 = 0
  let previous_2 = 0

  for row in rows
    if row == ''
      let sum += previous_1 - previous_2
      let previous_1 = 0
      let previous_2 = 0
    else
      let previous_2 = previous_1
      let previous_1 = row
    endif
  endfor

  if previous_1 != 0 && previous_2 == 0
    let sum += localtime() - previous_1
  endif

  let hours = sum / 3600
  let leftover_seconds = sum % 3600
  let minutes = leftover_seconds / 60
  let seconds = leftover_seconds % 60

  echom printf('Working for %d:%02d:%02d', hours, minutes, seconds)
endfunction

autocmd VimEnter * silent! call TimeTrackerClockIn() | redraw!
autocmd VimLeave * silent! call TimeTrackerClockOut()
nnoremap TT :call TimeTrackerStatus()<CR>
