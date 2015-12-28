let s:save_cpo = &cpo
set cpo&vim

function! lexima#string#to_inputtable(str)
  return substitute(a:str, '<\([A-Za-z\-\]\[]\+\)>', '\=eval(''"\<'' . submatch(1) . ''>"'')', 'g')
endfunction

function! lexima#string#to_mappable(str)
  return substitute(a:str, '<', '<LT>', 'g')
endfunction

function! lexima#string#to_upper_specialkey(str) abort
  return substitute(a:str, '\v\<\zs[A-Za-z\-]{-}\ze\>', '\=toupper(submatch(0))', 'g')
endfunction

" recursively take n characters
" Param: take_many(string, n, m, ...)
" Returns: [taken1 (with n length), taken2 (with m length), ..., rest]
function! lexima#string#take_many(str, ...)
  if a:0 ==# 0
    return [a:str]
  else
    let n = a:1
    if n <=# 0
      let pre_str = ''
    else
      let pre_str = a:str[0:n-1]
    endif
    if n >=# len(a:str)
      let post_str = ''
    else
      let post_str = a:str[(n):-1]
    endif
    return [pre_str] + call('lexima#string#take_many', [post_str] + a:000[1:-1])
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
