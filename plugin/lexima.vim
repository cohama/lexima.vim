let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_lexima')
  finish
endif
let g:loaded_lexima = 1

let g:lexima_no_default_rules = get(g:, 'lexima_no_default_rules', 0)
let g:lexima_no_map_to_escape = get(g:, 'lexima_no_escape_mapping', 0)
let g:lexima_highlight_future_input = get(g:, 'lexima_disable_highlight', 0)

function! s:define_highlights()
  hi def link leximaFutureInput MatchParen
endfunction
call s:define_highlights()


call lexima#init()

if !g:lexima_no_map_to_escape
  inoremap <Esc> <C-r>=lexima#insmode#leave_all('')<CR><Esc>
endif

augroup lexima
  autocmd InsertEnter * call lexima#insmode#clear_stack()
  autocmd ColorScheme * call s:define_highlights()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
