let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('lexima')
let s:L = s:V.import('Data.List')

let g:lexima#rules = [
\ {'char': '(', 'inputAfter': ')'},
\ {'char': ')', 'at': '\%#)', 'leave': 1},
\ {'char': '{', 'inputAfter': '}'},
\ {'char': '}', 'at': '\%#}', 'leave': 1},
\ {'char': '[', 'inputAfter': ']'},
\ {'char': ']', 'at': '\%#]', 'leave': 1},
\ {'char': '"', 'inputAfter': '"'},
\ {'char': '"', 'at': '\%#"', 'leave': 1},
\ {'char': "'", 'inputAfter': "'"},
\ {'char': "'", 'at': '\%#''', 'leave': 1},
\ ]

let s:lexima_rules = []
let s:leximastack = []

function! lexima#init()
  let s:lexima_rules = sort(deepcopy(g:lexima#rules), function('s:rule_priority_order'))
  for rule in s:L.uniq_by(s:lexima_rules, 'v:val.char')
    execute printf("inoremap %s \<C-r>=<SID>leximap(%s)\<CR>", rule.char, string(rule.char))
  endfor
  inoremap <Esc> <C-r>=<SID>escape()<CR><Esc>
endfunction

function! s:rule_priority_order(r1, r2)
  let l1 = len(get(a:r1, 'at', ''))
  let l2 = len(get(a:r2, 'at', ''))
  return l1 ==# l2 ? 0 : (l2 ># l1 ? 1 : -1)
endfunction

function! s:leximap(char)
  let rule = s:find_rule(a:char)
  if rule == {}
    return a:char
  elseif get(rule, 'leave', 0)
    return s:leave(rule.char, rule.at)
  else
    return get(rule, 'input', rule.char) . s:input(rule.inputAfter)
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

function! s:input(input)
  let curline = getline('.')
  let col = col('.')
  call setline('.', curline[0:col-2] . a:input . curline[col-1:-1])
  call add(s:leximastack, [a:input, col])
  return ''
endfunction

function! s:leave(input, at)
  let endpos = searchpos(a:at, 'bcWn')
  if endpos != [0, 0]
    let curline = getline('.')
    let col = endpos[1]
    call setline('.', curline[0:col-2] . curline[(col):-1])
    call remove(s:leximastack, -1)
  endif
  return a:input
endfunction

function! s:escape()
  let curline = getline('.')
  let col = col('.')
  if !empty(s:leximastack)
    let ret = join(reverse(map(s:leximastack, 'v:val[0]')), '')
    call setline('.', curline[0:col-2] . curline[(col-1 + len(ret)):-1])
  else
    let ret = ''
  endif
  let s:leximastack = []
  return ret
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
