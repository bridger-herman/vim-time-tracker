let g:time_tracker_config_file = '.time_tracker'

function! g:GetRootGitRepo()
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
  if !filereadable(g:time_tracker_config_file)
    return
  endif
  let rows = readfile(g:time_tracker_config_file)
  let rows = rows + [localtime()]
  if writefile(rows, g:time_tracker_config_file)
  endif
endfunction

function! g:TimeTrackerClockOut()
  if !filereadable(g:time_tracker_config_file)
    return
  endif
  let rows = readfile(g:time_tracker_config_file)
  let rows = rows + [localtime(), ""]
  if writefile(rows, g:time_tracker_config_file)
  endif
endfunction

function! g:TimeTrackerStatus()
  let rows = readfile(g:time_tracker_config_file)

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

  if previous_2 == 0
    let sum += localtime() - previous_1
  endif

  let hours = sum / 3600
  let leftover_seconds = sum % 3600
  let minutes = leftover_seconds / 60
  let seconds = leftover_seconds % 60

  echom printf('Working for %d:%02d:%02d', hours, minutes, seconds)
endfunction

" autocmd VimEnter * call TimeTrackerClockIn()
" autocmd VimLeave * call TimeTrackerClockOut()
