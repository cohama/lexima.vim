let s:save_cpo = &cpo
set cpo&vim

let s:input_stack = lexima#charstack#new()
let s:mapped_chars = []
let s:rules = lexima#sortedlist#new([], function('lexima#insmode#_priority_order'))

function! lexima#insmode#add_rules(rule)
  call s:rules.add(a:rule)
  call s:define_map(a:rule.char, a:rule.char, '', '')
endfunction

function! lexima#insmode#clear_rules()
  for c in s:mapped_chars
    execute "iunmap " . c
  endfor
  let s:mapped_chars = []
  call s:rules.clear()
endfunction

function! s:define_map(char, mapping, prehook, posthook)
  if index(s:mapped_chars, a:char) ==# -1
    execute printf("inoremap <silent> %s %s\<C-r>=<SID>map_impl(%s, %s)\<CR>%s", a:char, a:prehook, string(lexima#string#to_mappable(a:mapping)), string(lexima#string#to_mappable(a:char)), a:posthook)
    call add(s:mapped_chars, a:char)
  endif
endfunction

function! lexima#insmode#define_altanative_key(char, mapping)
  call s:define_map(a:char, a:mapping, '', '')
endfunction

function! lexima#insmode#map_hook(when, char, expr)
  let i = index(s:mapped_chars, a:char)
  if i !=# -1
    call remove(s:mapped_chars, i)
  endif
  if a:when ==# 'before'
    call s:define_map(a:char, a:char, a:expr, '')
  elseif a:when ==# 'after'
    call s:define_map(a:char, a:char, '', a:expr)
  endif
endfunction

function! s:map_impl(char, fallback)
  let fallback = lexima#string#to_inputtable(a:fallback)
  if &buftype ==# 'nofile'
    return fallback
  endif
  let rule = s:find_rule(a:char)
  if rule == {}
    return fallback
  else
    if has_key(rule, 'leave')
      if type(rule.leave) ==# type('')
        let input = printf('<C-r>=lexima#insmode#leave_till(%s, %s)<CR>', string(rule.leave), string(lexima#string#to_mappable(a:fallback)))
      elseif type(rule.leave) ==# type(0)
        let input = printf('<C-r>=lexima#insmode#leave(%d, %s)<CR>', rule.leave, string(lexima#string#to_mappable(a:fallback)))
      else
        throw 'lexima: Not applicable rule (' . string(rule) . ')'
      endif
      let input_after = ''
    elseif has_key(rule, 'delete')
      if type(rule.delete) ==# type('')
        let input = printf('<C-r>=lexima#insmode#delete_till(%s, %s)<CR>', string(rule.delete), string(lexima#string#to_mappable(a:fallback)))
      elseif type(rule.delete) ==# type(0)
        let input = printf('<C-r>=lexima#insmode#delete(%d, %s)<CR>', rule.delete, string(lexima#string#to_mappable(a:fallback)))
      else
        throw 'lexima: Not applicable rule (' . string(rule) . ')'
      endif
      let input = input . rule.input
      let input_after = ''
    else
      let input = rule.input
      let input_after = rule.input_after
    endif
    return s:input(lexima#string#to_inputtable(input), lexima#string#to_inputtable(input_after))
  endif
endfunction

function! s:find_rule(char)
  let syntax_chain = s:get_syntax_link_chain()
  for rule in s:rules.as_list()
    if rule.char ==# a:char
      let endpos = searchpos(rule.at, 'bcWn')
      if endpos !=# [0, 0]
        if empty(rule.filetype) || index(rule.filetype, &filetype) >=# 0
          if empty(rule.syntax)
            return rule
          else
            for syn in syntax_chain
              if index(rule.syntax, syn) >=# 0
                return rule
              endif
            endfor
          endif
        endif
      endif
    endif
  endfor
  return {}
endfunction

function! lexima#insmode#_priority_order(rule1, rule2)
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
      let pri1 = a:rule1.priority
      let pri2 = a:rule2.priority
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

function! s:get_syntax_link_chain()
  let l = line('.')
  let c = col('.')
  let synname = synIDattr(synID(l, c, 1), "name")
  let result_stack = []
  if synname ==# '' && c > 1
    let synname = synIDattr(synID(l, c-1, 1), "name")
  endif
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
  let [precursor, _] = lexima#string#take_many(curline, col-1)
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
      call setpos('.', [0, lnum+i, 0, 0])
      let v:lnum = lnum+i
      let indent_depth = eval(&l:indentexpr)
    endif
    " TODO: in case of 'noexpandtab'
    call setline(lnum+i, repeat(' ', indent_depth) . getline(lnum+i))
  endfor
  call setpos('.', [bufnum, lnum, col, off])
  call s:input_stack.push(a:input_after)
  return a:input
endfunction

function! lexima#insmode#leave(len, fallback)
  if s:input_stack.is_empty()
    return lexima#string#to_inputtable(a:fallback)
  endif
  let input = s:input_stack.peek(a:len)
  let [bufnum, lnum, col, off] = getpos('.')
  let cr_count = len(split(input, "\r", 1)) - 1
  let will_input = substitute(input, "\r", '\\n\\s\\*', 'g')
  let illegal = search('\V\%#' . will_input) ==# 0
  if illegal
    return lexima#string#to_inputtable(a:fallback)
  endif
  for i in range(1, cr_count)
    call setline(lnum+i, substitute(getline(lnum+i), '^\s*', '', ''))
  endfor
  if cr_count !=# 0
    execute 'join! ' . (cr_count + 1)
  endif
  call setpos('.', [bufnum, lnum, col, off])
  let curline = getline('.')
  let len = len(input) - cr_count
  let [precursor, _, postcursor] = lexima#string#take_many(curline, col-1, len)
  call setline('.', precursor . postcursor)
  return s:input_stack.pop(a:len)
endfunction

function! lexima#insmode#leave_till(char, fallback)
  let input = s:input_stack.peek(0)
  let tilllen = match(input, a:char)
  if tilllen ==# -1
    return ''
  else
    return lexima#insmode#leave(tilllen + len(a:char), a:fallback)
  endif
endfunction

function! lexima#insmode#leave_all(fallback)
  return lexima#insmode#leave(s:input_stack.count(), a:fallback)
endfunction

function! lexima#insmode#leave_till_eol(fallback)
  let input = s:input_stack.peek(0)
  return lexima#insmode#leave(len(split(input, "\r")[0]), a:fallback)
endfunction

function! lexima#insmode#delete(len, fallback)
  call lexima#insmode#leave(a:len, a:fallback)
  return ''
endfunction

function! lexima#insmode#delete_till(char, fallback)
  call lexima#insmode#leave_till(a:char, a:fallback)
  return ''
endfunction

function! lexima#insmode#delete_all(fallback)
  call lexima#insmode#leave_all(a:fallback)
  return ''
endfunction

function! lexima#insmode#escape()
  let pos_save = getpos('.')
  try
    let ret = lexima#insmode#leave_all('')
    let ret .= "\<C-r>=setpos('.', " . string(pos_save) . ")?'':''\<CR>"
  catch
    call setpos('.', pos_save)
    let ret = ''
  endtry
  return ret
endfunction

function! lexima#insmode#delete_till_eol(fallback)
  call lexima#insmode#leave_till_eol(a:fallback)
  return ''
endfunction

function! lexima#insmode#clear_stack()
  if !s:input_stack.is_empty()
    call s:input_stack.pop_all()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
