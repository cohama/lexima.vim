let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('lexima')
let s:L = s:V.import('Data.List')
let s:S = s:V.import('Data.String')

let s:lexima_vital = {
\ 'V' : s:V,
\ 'L' : s:L,
\ 'S' : s:S
\ }

function! lexima#vital()
  return s:lexima_vital
endfunction

let g:lexima#rules = [
\ {'char': '(', 'input_after': ')'},
\ {'char': ')', 'at': '\%#)', 'leave': 1},
\ {'char': '{', 'input_after': '}'},
\ {'char': '}', 'at': '\%#\n\s*}', 'leave': 1, 'input': '<CR>}'},
\ {'char': '}', 'at': '\%#}', 'leave': 1},
\ {'char': '[', 'input_after': ']'},
\ {'char': ']', 'at': '\%#]', 'leave': 1},
\ {'char': '"', 'input_after': '"'},
\ {'char': '"', 'at': '\%#"', 'leave': 1},
\ {'char': "'", 'input_after': "'"},
\ {'char': "'", 'at': '\%#''', 'leave': 1},
\ {'char': "%", 'at': '<\%#', 'input_after': '%>'},
\ {'char': "%", 'at': '\%#%>', 'input': '%>', 'leave': 1},
\ {'char': '<CR>', 'at': '{\%#}', 'input_after': '<CR>'},
\ ]

let s:lexima_rules = []
let s:input_stack = lexima#charstack#new()

function! GetInputStack()
  return s:input_stack
endfunction

function! lexima#init()
  let s:lexima_rules = sort(deepcopy(g:lexima#rules), function('s:rule_priority_order'))
  for rule in s:L.uniq_by(s:lexima_rules, 'v:val.char')
    execute printf("inoremap %s \<C-r>=<SID>leximap('%s')\<CR>", rule.char, substitute(s:map_char(rule.char), "'", "''", 'g'))
  endfor
  inoremap <Esc> <C-r>=<SID>escape()<CR><Esc>
endfunction

function! s:map_char(char)
  return substitute(a:char, '<', '<LT>', 'g')
endfunction

function! s:special_char(char)
  return substitute(a:char, '<\([A-Za-z\-]\+\)>', '\=eval(''"\<'' . submatch(1) . ''>"'')', 'g')
endfunction

function! s:rule_priority_order(r1, r2)
  let l1 = len(get(a:r1, 'at', ''))
  let l2 = len(get(a:r2, 'at', ''))
  return l1 ==# l2 ? 0 : (l2 ># l1 ? 1 : -1)
endfunction

function! s:leximap(char)
  let rule = s:find_rule(a:char)
  if rule == {}
    return s:special_char(a:char)
  elseif get(rule, 'leave', 0)
    return s:leave(s:special_char(a:char), s:special_char(get(rule, 'input', rule.char)), rule.at)
  else
    return s:special_char(get(rule, 'input', rule.char)) . s:input(s:special_char(get(rule, 'input_after', '')))
  endif
endfunction

function! s:find_rule(char)
  for rule in s:lexima_rules
    if rule.char !=# a:char
      continue
    endif

    let endpos = searchpos(get(rule, 'at', '\%#'), 'bcWn')

    if endpos ==# [0, 0]
      continue
    endif

    return rule
  endfor
  return {}
endfunction

function! s:input(input_after)
  let curline = getline('.')
  let col = col('.')
  let inputs = split(a:input_after, "\r", 1)
  let inputs[0] = curline[0:col-2] . inputs[0]
  let inputs[-1] = inputs[-1] . curline[col-1:-1]
  call setline('.', inputs[0])
  let [bufnum, lnum, _, off] = getpos('.')
  for i in range(1, len(inputs)-1)
    call append(lnum+i-1, inputs[i])
    call setpos('.', [bufnum, lnum+i, col, off])
    if &indentexpr ==# ''
      if &smartindent || &cindent
        let indent_depth = cindent(lnum+i)
      elseif &autoindent
        let indent_depth = indent(lnum)
      else
        let indent_depth = 0
      endif
    else
      execute 'let indent_depth = ' . &indentexpr
    endif
    call setline(lnum+i, repeat(' ', indent_depth) . getline(lnum+i))
  endfor
  call setpos('.', [bufnum, lnum, col, off])
  call s:input_stack.push(a:input_after)
  return ''
endfunction

function! s:leave_impl(input)
  let col = col('.')
  let cr_count = len(split(a:input, "\r", 1)) - 1
  let will_input = substitute(a:input, "\r", '\\n\\s*', 'g')
  let illegal = search('\%#' . will_input) ==# 0
  if illegal
    return 0
  endif
  let [bufnum, lnum, _, off] = getpos('.')
  for i in range(1, cr_count)
    call setline(lnum+i, substitute(getline(lnum+i), '^\s*', '', ''))
  endfor
  if cr_count !=# 0
    execute 'join! ' . (cr_count + 1)
  endif
  call setpos('.', [bufnum, lnum, col, off])
  let curline = getline('.')
  let len = len(a:input) - cr_count
  if col ==# 1
    let precursor = ''
  else
    let precursor = curline[0:col-2]
  endif
  let endcol = col('$') - len
  if col ==# endcol
    let postcursor = ''
  else
    let postcursor = curline[(col-1+len):-1]
  endif
  call setline('.', precursor . postcursor)
  return 1
endfunction

function! s:leave(fallback, input, at)
  if s:input_stack.is_empty()
    return a:input
  endif
  let endpos = searchpos(a:at, 'bcWn')
  if endpos != [0, 0]
    if s:leave_impl(a:input)
      call s:input_stack.pop(len(a:input))
      return a:input
    endif
  endif
  return a:fallback
endfunction

function! s:escape()
  let curline = getline('.')
  let col = col('.')
  if s:input_stack.is_empty()
    let ret = ''
  else
    echomsg string(s:input_stack)
    let remaining = s:input_stack.pop_all()
    if s:leave_impl(remaining)
      let ret = remaining
    else
      let ret = ''
    endif
  endif
  return ret
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
