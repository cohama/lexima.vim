let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_lexima')
  finish
endif
let g:loaded_lexima = 1

call lexima#init()

let &cpo = s:save_cpo
unlet s:save_cpo
