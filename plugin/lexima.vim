let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_lexima')
  finish
endif
let g:loaded_lexima = 1


if !exists('g:lexima_map_escape')
  let g:lexima_map_escape = '<Esc>'
endif


function! s:setup_insmode()
  if get(b:, 'lexima_disabled', 0)
    return
  endif

  if -1 == match(&backspace, 'start')
    echohl WarningMsg
    echom "lexima: 'backspace' option does not contain 'start'. (Recommendation: set backspace=indent,eol,start)"
    echohl None
  endif

  " Setup workaround to be able to map `Esc` in insert mode, in combination with
  " the "nowait" mapping. This is required in terminal mode, where escape codes
  " are being used for cursor keys, alt/meta mappings etc.
  if g:lexima_map_escape == '<Esc>' && !has('gui_running')
    inoremap <Esc><Esc> <Esc>
  endif
  if g:lexima_map_escape !=# ''
    " let lexima_escape = lexima#insmode#mapping_expr("lexima#insmode#escape()")
    let g:_lexima_escape = "\<Cmd>call lexima#insmode#_do('lexima#insmode#escape()')\<CR>"
    if v:version > 703 || (v:version == 703 && has("patch1261"))
      exe 'inoremap <expr><silent><buffer><nowait> ' . g:lexima_map_escape . " g:_lexima_escape"
    else
      exe 'inoremap <silent> <buffer> ' . g:lexima_map_escape . ' ' . lexima_escape
    endif
  endif
endfun

augroup lexima-init
  autocmd!
  autocmd InsertEnter * call lexima#init() | autocmd! lexima-init
augroup END

augroup lexima
  autocmd!
  autocmd InsertEnter * call lexima#insmode#clear_stack()
  autocmd InsertEnter * call s:setup_insmode()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
