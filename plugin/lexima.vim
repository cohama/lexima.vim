let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_lexima')
  finish
endif
let g:loaded_lexima = 1

let g:lexima_no_default_rules = get(g:, 'lexima_no_default_rules', 0)
let g:lexima_no_map_to_escape = get(g:, 'lexima_no_map_to_escape', 0)
let g:lexima_enable_basic_rules = get(g:, 'lexima_enable_basic_rules', 1)
let g:lexima_enable_newline_rules = get(g:, 'lexima_enable_newline_rules', 1)
let g:lexima_enable_endwise_rules = get(g:, 'lexima_enable_endwise_rules', 0)

if g:lexima_no_default_rules
  call lexima#init()
endif

if !g:lexima_no_map_to_escape
  inoremap <Esc> <C-r>=lexima#insmode#escape()<CR><Esc>
endif

augroup lexima
  autocmd!
  autocmd InsertEnter * call lexima#insmode#clear_stack()
  autocmd ColorScheme * call s:define_highlights()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
