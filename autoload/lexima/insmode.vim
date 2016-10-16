let s:save_cpo = &cpo
set cpo&vim

let s:B = lexima#vital().B
let s:L = lexima#vital().L

let s:input_stack = lexima#charstack#new()

" mapping dictionary. e.g.
" {
"   '(': {
"     'rules': {
"       '_': [{'at': ...}, {'at': ...}, {}, ...],
"       'haskell': [{'at': ...}, {'at': ...}, {}, ...],
"       'javascript': [{'at': ...}, {'at': ...}, {}, ...],
"       'ruby': [{'at': ...}, {'at': ...}, {}, ...],
"     },
"     'prehook': function(),
"     'posthook': function()
"   }
" }
let s:map_dict = {}

function! lexima#insmode#get_rules()
  return s:map_dict
endfunction

function! lexima#insmode#get_map_rules(char) abort
  let char = lexima#string#to_upper_specialkey(a:char)
  if has_key(s:map_dict, char)
    if &filetype == '' || !s:L.has(keys(s:map_dict[char].rules), &filetype)
      return s:map_dict[char].rules['_'].as_list()
    else
      return s:map_dict[char].rules[&filetype].as_list() +
      \ s:map_dict[char].rules['_'].as_list()
    endif
  else
    return []
  endif
endfunction

function! lexima#insmode#_default_prehook(char) abort
  " Add <C-]> prehook to expand abbreviation.
  if (v:version > 703 || (v:version == 703 && has('patch489'))) " old vim does not support <C-]>
  \ && lexima#string#to_inputtable(a:char) !~ '.*\k$'
    if pumvisible() && a:char == '<CR>'
      return '<C-y><C-]>'
    else
      return '<C-]>'
    endif
  else
    return ''
  endif
endfunction

function! lexima#insmode#_default_posthook(char) abort
  return ''
endfunction

function! lexima#insmode#add_rules(rule) abort
  " Expect a:rule to be regularized.
  if has_key(s:map_dict, a:rule.char)
    let newchar_flg = 0
  else
    let s:map_dict[a:rule.char] = {
    \ 'rules': {
    \     '_': lexima#sortedlist#new([], function('lexima#insmode#_priority_order'))
    \   },
    \ 'prehook': function('lexima#insmode#_default_prehook'),
    \ 'posthook': function('lexima#insmode#_default_posthook'),
    \ }
    let newchar_flg = 1
  endif
  let ft_keys = empty(a:rule.filetype) ? ['_'] : a:rule.filetype
  for ft in ft_keys
    if !has_key(s:map_dict[a:rule.char].rules, ft)
      let s:map_dict[a:rule.char].rules[ft] = lexima#sortedlist#new([], function('lexima#insmode#_priority_order'))
    endif
    call s:map_dict[a:rule.char].rules[ft].add(a:rule)
  endfor
  " Define imap in the last of the function in order to avoid invalid mapping
  " definition when an error occur.
  if newchar_flg
    if has('nvim') && a:rule.char == '<CR>'
      execute printf("inoremap <expr><silent> %s pumvisible() ? \"\\<C-y>\" : lexima#expand(%s, 'i')",
                    \ a:rule.char,
                    \ string(lexima#string#to_mappable(a:rule.char))
                    \ )
    else
      execute printf("inoremap <expr><silent> %s lexima#expand(%s, 'i')",
                    \ a:rule.char,
                    \ string(lexima#string#to_mappable(a:rule.char))
                    \ )
    endif
  endif
endfunction

function! lexima#insmode#clear_rules()
  for c in keys(s:map_dict)
    execute "iunmap " . c
  endfor
  let s:map_dict = {}
endfunction

function! lexima#insmode#_expand(char) abort
  let char = lexima#string#to_upper_specialkey(a:char)
  let fallback = lexima#string#to_inputtable(a:char)
  if !has_key(s:map_dict, char) || mode() !=# 'i'
    return fallback
  endif
  let map = s:map_dict[char]
  let prehook = lexima#string#to_inputtable(
  \ (type(map.prehook)) ==# type(function("tr")) ? call(map.prehook, [a:char]) : map.prehook
  \ )
  let posthook = lexima#string#to_inputtable(
  \ (type(map.posthook)) ==# type(function("tr")) ? call(map.posthook, [a:char]) : map.posthook
  \ )
  return printf("%s\<C-r>=lexima#insmode#_map_impl(%s)\<CR>%s",
              \ prehook,
              \ string(char),
              \ posthook
              \ )
endfunction

function! lexima#insmode#_map_impl(char) abort
  return s:map_impl(a:char)
endfunction

function! lexima#insmode#define_altanative_key(char, mapping)
  execute printf("inoremap <expr><silent> %s lexima#expand(%s, 'i')",
               \ a:char,
               \ string(lexima#string#to_mappable(a:mapping))
               \ )
endfunction

function! lexima#insmode#map_hook(when, char, expr)
  let char = lexima#string#to_upper_specialkey(a:char)
  if !has_key(s:map_dict, char)
    throw 'lexima: no rule to add map hook (' . a:char . ').'
  endif
  if a:when ==# 'before'
    let s:map_dict[char].prehook = a:expr
  elseif a:when ==# 'after'
    let s:map_dict[char].posthook = a:expr
  endif
endfunction

function! s:map_impl(char)
  let fallback = lexima#string#to_inputtable(a:char)
  if &buftype ==# 'nofile' && !s:B.is_cmdwin()
    return fallback
  endif
  if exists('b:lexima_disabled') && b:lexima_disabled
    return fallback
  endif
  let rule = s:find_rule(a:char)
  if rule == {}
    return fallback
  else
    if has_key(rule, 'leave')
      if type(rule.leave) ==# type('')
        let input = printf('<C-r>=lexima#insmode#leave_till(%s, %s)<CR>', string(rule.leave), string(lexima#string#to_mappable(a:char)))
      elseif type(rule.leave) ==# type(0)
        let input = printf('<C-r>=lexima#insmode#leave(%d, %s)<CR>', rule.leave, string(lexima#string#to_mappable(a:char)))
      else
        throw 'lexima: Not applicable rule (' . string(rule) . ')'
      endif
      let input_after = ''
    elseif has_key(rule, 'delete')
      if type(rule.delete) ==# type('')
        let input = printf('<C-r>=lexima#insmode#delete_till(%s, %s)<CR>', string(rule.delete), string(lexima#string#to_mappable(a:char)))
      elseif type(rule.delete) ==# type(0)
        let input = printf('<C-r>=lexima#insmode#delete(%d, %s)<CR>', rule.delete, string(lexima#string#to_mappable(a:char)))
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
  let searchlimit = max([0, line('.') - 20])
  let rules = lexima#insmode#get_map_rules(a:char)
  for rule in rules
    let endpos = searchpos(rule.at, 'bcWn', searchlimit)
    let excepted = has_key(rule, 'except') ?
    \              searchpos(rule.except, 'bcWn', searchlimit) !=# [0, 0] : 0
    if endpos !=# [0, 0] && !excepted
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

    if &expandtab
      let indent = repeat(' ', indent_depth)
    else
      let indent = repeat("\t", indent_depth / &tabstop)
      \            . repeat(' ', indent_depth % &tabstop)
    endif

    call setline(lnum+i, indent . getline(lnum+i))
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
  let illegal = search('\V\%#' . will_input, 'bcWn') ==# 0
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
    return lexima#string#to_inputtable(a:fallback)
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
