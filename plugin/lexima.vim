let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_lexima')
  finish
endif
let g:loaded_lexima = 1

call lexima#init()

if !g:lexima_no_map_to_escape
  inoremap <silent> <Esc> <C-r>=lexima#insmode#escape()<CR><Esc>
endif

augroup lexima
  autocmd!
  autocmd InsertEnter * call lexima#insmode#clear_stack()

  if g:lexima_fix_arrow_keys_behavior && !has('gui_running')
    autocmd InsertLeave * call s:fix_arrow_keys_behavior()
  endif

augroup END

function! s:fix_arrow_keys_behavior()
  nnoremap OA a<Up>
  nnoremap OB a<Down>
  nnoremap <expr> OC col("'^") == 1 ? "i\<Right>" : "a\<Right>"
  nnoremap OD a<Left>
  augroup lexima-fix-arrow-keys-behavior
    autocmd CursorHold * call s:after_fix_arrow_keys_behavior()
  augroup END
  let s:save_ut = &updatetime
  set updatetime=10
endfunction

function! s:after_fix_arrow_keys_behavior()
  let &updatetime = s:save_ut
  autocmd! lexima-fix-arrow-keys-behavior
  if maparg('OA', 'n') !=# ''
    nunmap OA
    nunmap OB
    nunmap OC
    nunmap OD
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
