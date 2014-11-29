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
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
