" svnim.vim - SVN IMproved plugin
" Author:       Albo <rsarce@gmail.com>
" URL:          https://github.com/4lb0/svim

function! s:ShowMessage(message)
  echohl Folded | echo "svn " . a:message | echohl None
endfunction

function! s:Commit()
  let remove_prefix = 'substitute(v:val, ".x.........", "", "")'
  let svn_status = getline(2,'$')
  let prepare_to_commit = filter(svn_status, 'v:val =~ "^\\[x\\].*"')
  let files_to_commit = map(prepare_to_commit, remove_prefix)
  let one_line_files_to_commit = join(files_to_commit, " ")
  let svn_status = getline(2,'$')
  let prepare_to_add = filter(svn_status, 'v:val =~ "^.x..\?.*"')
  let files_to_add = map(prepare_to_add, remove_prefix)   
  let i = 0
  let total = len(files_to_add)
  while i < total
    execute "silent !svn add " . files_to_add[i]
    let i += 1
  endwhile
  execute "silent !svn commit " . one_line_files_to_commit
  quit!
  redraw!
endfunction    

function! s:PrepareToCommit()
  let number = line('.')
  let line = getline('.')
  if number == 1
      let number = "%"
  end
  if line[1:1] == " "
    exe number . 's/^. ./[x]/'
  else
    exe number . 's/^.x./[ ]/'
  endif
endfunction

"
" use sd to get the current diff
" or use 123sd to get the diff of change 123
function! s:Diff(count)    
  call s:ShowMessage("diff")
  if a:count > 0
    exe "silent tabnew  svn\\ diff\\ " . a:count
    exe "read !svn diff -c" . a:count
  else
    silent tabnew  svn\ diff
    read !svn diff
  endif
  set filetype=diff
endfunction

function! s:Update()
  call s:ShowMessage("update")
  silent botright 5new svn\ up 
  0read !svn update 
endfunction

function! s:Status()
  if @% == "svn status"
    quit!
  endif
  call s:ShowMessage("status")
  silent botright 5new svn\ status
  silent 0s/$/Apply to all/
  silent $read !svn status 
  silent %s/^/[ ] /g
  set filetype=svnstatus
  redraw!
  if line('w$') == 1
    q!
    call s:ShowMessage("status - no modifications")
  endif
endfunction

function! s:Log(count)
  call s:ShowMessage("log")
  let limit = a:count > 0 ? a:count : 10
  exe "silent botright 10new svn\\ log\\ " . limit
  exe "read !svn log -v --limit=" . limit
  " TODO: using tags to call svn diff is not working because of sandbox
  " exe 'read !svn log -v --limit=' . limit . ' | sed \'s/\\(r[0-9]*\\) /*\\1* /\''
  " set filetype=help
  for entry in taglist('r.*')
    echo entry 
  endfor
endfunction

if !exists('g:svnim_map_prefix')
  let g:svnim_map_prefix = '<leader>'
endif

execute "nnoremap <silent> " . g:svnim_map_prefix . "sd :<C-U>call s:Diff(v:count)<CR>"
execute "nnoremap <silent> " . g:svnim_map_prefix . "ss :call s:Status()<CR>"
execute "nnoremap <silent> " . g:svnim_map_prefix . "su :call s:Update()<CR>"
execute "nnoremap <silent> " . g:svnim_map_prefix . "sl :<C-U>call s:Log(v:count)<CR>"

autocmd FileType svnstatus nnoremap <silent> x :<C-U>call s:PrepareToCommit()<CR>
autocmd FileType svnstatus nnoremap <silent> c :<C-U>call s:Commit()<CR>

