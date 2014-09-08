let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_lexima')
  finish
endif
let g:loaded_lexima = 1

let g:lexima_no_default_rules = get(g:, 'lexima_no_default_rules', 0)
let g:lexima_no_map_to_escape = get(g:, 'lexima_no_escape_mapping', 0)

call lexima#init()

if !g:lexima_no_map_to_escape
  inoremap <Esc> <C-r>=lexima#escape()<CR><Esc>
endif

let &cpo = s:save_cpo
unlet s:save_cpo
