let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('lexima')
let s:L = s:V.import('Data.List')
let s:S = s:V.import('Data.String')

let s:lexima_vital = {
\ 'L' : s:L,
\ 'S' : s:S
\ }

let s:default_rule = {
\ 'at': '\%#',
\ 'leave': 0,
\ 'filetype': [],
\ 'syntax': [],
\ 'mode': 'i'
\ }

let s:lexima_mapped_chars = []

let g:lexima#default_rules = [
\ {'char': '(', 'input_after': ')'},
\ {'char': ')', 'at': '\%#)', 'leave': 1},
\ {'char': '{', 'input_after': '}'},
\ {'char': '}', 'at': '\%#\n\s*}', 'leave': 2},
\ {'char': '}', 'at': '\%#}', 'leave': 1},
\ {'char': '[', 'input_after': ']'},
\ {'char': ']', 'at': '\%#]', 'leave': 1},
\ {'char': '"', 'input_after': '"'},
\ {'char': '"', 'at': '\%#"', 'leave': 1},
\ {'char': "'", 'input_after': "'"},
\ {'char': "'", 'at': '\%#''', 'leave': 1},
\ {'char': "%", 'at': '<\%#', 'input_after': '%>'},
\ {'char': "%", 'at': '\%#%>', 'input': '%>', 'leave': 2},
\ {'char': '<CR>', 'at': '{\%#}', 'input_after': '<CR>'},
\ ]

function! lexima#vital()
  return s:lexima_vital
endfunction

function! lexima#init()
  let s:input_stack = lexima#charstack#new()
  let s:lexima_mapped_chars = []
  let default_rules = g:lexima_no_default_rules ? [] : map(deepcopy(g:lexima#default_rules), 's:regularize(v:val)')
  let s:lexima_rules = lexima#sortedlist#new(default_rules, function('lexima#_priority_order'))
  for rule in default_rules
    call s:define_map(rule.char)
  endfor
endfunction

function! lexima#clear_rules()
  for c in s:lexima_mapped_chars
    execute "iunmap " . c
  endfor
  let s:lexima_mapped_chars = []
  call s:lexima_rules.clear()
endfunction

function! lexima#add_rule(rule)
  let rule = s:regularize(a:rule)
  call s:lexima_rules.add(rule)
  call s:define_map(rule.char)
endfunction

function! s:map_char(char)
  return substitute(a:char, '<', '<LT>', 'g')
endfunction

function! s:define_map(c)
  if index(s:lexima_mapped_chars, a:c) ==# -1
    execute printf("inoremap %s \<C-r>=<SID>leximap('%s')\<CR>", a:c, substitute(s:map_char(a:c), "'", "''", 'g'))
    call add(s:lexima_mapped_chars, a:c)
  endif
endfunction

function! s:special_char(char)
  return substitute(a:char, '<\([A-Za-z\-]\+\)>', '\=eval(''"\<'' . submatch(1) . ''>"'')', 'g')
endfunction

function! s:leximap(char)
  let rule = s:find_rule(a:char)
  if rule == {}
    return s:special_char(a:char)
  elseif rule.leave ># 0
    return s:leave(s:special_char(a:char), rule.leave)
  else
    return s:input(s:special_char(get(rule, 'input', rule.char)), s:special_char(get(rule, 'input_after', '')))
  endif
endfunction

function! s:find_rule(char)
  let syntax_chain = s:get_syntax_link_chain()
  for rule in s:lexima_rules.as_list()
    if rule.char !=# a:char
      continue
    endif

    let endpos = searchpos(rule.at, 'bcWn')

    if endpos ==# [0, 0]
      continue
    endif

    if !empty(rule.filetype)
      if index(rule.filetype, &filetype) ==# -1
        continue
      endif
    endif

    if !empty(rule.syntax)
      let found = 0
      for syn in syntax_chain
        if index(rule.syntax, syn) >=# 0
          let found = 1
          break
        endif
      endfor
      if !found
        continue
      endif
    endif

    return rule
  endfor
  return {}
endfunction

function! s:get_syntax_link_chain()
  let synname = synIDattr(synID(line('.'), col('.'), 1), "name")
  let result_stack = []
  while 1
    if synname ==# ''
      break
    endif
    call add(result_stack, synname)
    redir => hiresult
      execute 'silent! highlight ' . synname
    redir END
    let synname = matchstr(hiresult, 'links to \zs\w\+')
  endwhile
  return result_stack
endfunction

function! s:input(input, input_after)
  let curline = getline('.')
  let [bufnum, lnum, col, off] = getpos('.')
  let inputs = split(a:input_after, "\r", 1)
  if col ==# 1
    let precursor = ''
  else
    let precursor = curline[0:col-2]
  endif
  let inputs[0] = precursor . inputs[0]
  let inputs[-1] = inputs[-1] . curline[col-1:-1]
  call setline('.', inputs[0])
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
      let indent_depth = eval(&indentexpr)
    endif
    " TODO: in case of 'noexpandtab'
    call setline(lnum+i, repeat(' ', indent_depth) . getline(lnum+i))
  endfor
  call setpos('.', [bufnum, lnum, col, off])
  call s:input_stack.push(a:input_after)
  return a:input
endfunction

function! s:leave_impl(len)
  let input = s:input_stack.peek(a:len)
  verb echomsg "i: " . input
  let col = col('.')
  let cr_count = len(split(input, "\r", 1)) - 1
  let will_input = substitute(input, "\r", '\\n\\s*', 'g')
  let illegal = search('\%#' . will_input) ==# 0
  if illegal
    return ''
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
  let len = len(input) - cr_count
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
  return s:input_stack.pop(a:len)
endfunction

function! s:leave(fallback, len)
  if s:input_stack.is_empty()
    return a:fallback
  endif
  let input = s:input_stack.peek(a:len)
  let ret = s:leave_impl(a:len)
  if !empty(ret)
    return input
  else
    return a:fallback
  endif
endfunction

function! lexima#escape()
  let curline = getline('.')
  let col = col('.')
  if s:input_stack.is_empty()
    let ret = ''
  else
    let remaining = s:input_stack.peek(0)
    if !empty(s:leave_impl(len(remaining)))
      let ret = remaining
    else
      let ret = ''
    endif
  endif
  return ret
endfunction

function! s:regularize(rule)
  let reg_rule = extend(deepcopy(a:rule), s:default_rule, 'keep')
  if type(reg_rule.filetype) !=# type([])
    let reg_rule.filetype = [reg_rule.filetype]
  endif
  if type(reg_rule.syntax) !=# type([])
    let reg_rule.syntax = [reg_rule.syntax]
  endif
  return reg_rule
endfunction

function! lexima#_priority_order(rule1, rule2)
  let ft1 = !empty(a:rule1.filetype)
  let ft2 = !empty(a:rule2.filetype)
  if ft1 && !ft2
    return 1
  elseif ft2 && !ft1
    return -1
  else
    let syn1 = !empty(a:rule1.syntax)
    let syn2 = !empty(a:rule2.syntax)
    if syn1 && !syn2
      return 1
    elseif syn2 && !syn1
      return -1
    else
      let pri1 = get(a:rule1, 'priority', 0)
      let pri2 = get(a:rule2, 'priority', 0)
      if pri1 > pri2
        return 1
      elseif pri1 < pri2
        return -1
      else
        let atlen1 = len(a:rule1.at)
        let atlen2 = len(a:rule2.at)
        if atlen1 > atlen2
          return 1
        elseif atlen1 < atlen2
          return -1
        else
          return 0
        endif
      endif
    endif
  endif
endfunction

function! lexima#get_rules()
  if exists('s:lexima_rules')
    return s:lexima_rules.as_list()
  else
    return []
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
