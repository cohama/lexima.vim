let s:save_cpo = &cpo
set cpo&vim

let s:L = lexima#vital().L

let s:map_dict = {}

let s:magic_cursor_string = '__LEXIMA_CMDLINE_CURSOR__'

function! lexima#cmdmode#get_map_rules(char) abort
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

function! lexima#cmdmode#_default_prehook(char) abort
  if lexima#string#to_inputtable(a:char) !~ '.*\k$' && !g:lexima_disable_abbrev_trigger
    return '<C-]>'
  else
    return ''
  endif
endfunction

function! lexima#cmdmode#add_rules(rule)
  " Expect a:rule to be regularized.
  if has_key(s:map_dict, a:rule.char)
    let newchar_flg = 0
  else
    let s:map_dict[a:rule.char] = {
    \ 'rules': {
    \     '_': lexima#sortedlist#new([], function('lexima#cmdmode#_priority_order'))
    \   },
    \ 'prehook': function('lexima#cmdmode#_default_prehook'),
    \ 'posthook': '',
    \ }
    " Add <C-]> prehook to expand abbreviation.
    if (v:version > 703 || (v:version == 703 && has('patch489'))) " old vim does not support <C-]>
    \ && lexima#string#to_inputtable(a:rule.char) !~ '.*\k$'
      let s:map_dict[a:rule.char].prehooks = ['<C-]>']
    endif
    let newchar_flg = 1
  endif
  let ft_keys = empty(a:rule.filetype) ? ['_'] : a:rule.filetype
  for ft in ft_keys
    if !has_key(s:map_dict[a:rule.char].rules, ft)
      let s:map_dict[a:rule.char].rules[ft] = lexima#sortedlist#new([], function('lexima#cmdmode#_priority_order'))
    endif
    call s:map_dict[a:rule.char].rules[ft].add(a:rule)
  endfor
  " define imap in the last of the function in order avoid invalid mapping
  " definition when an error occur.
  if newchar_flg
    execute printf("cnoremap <expr> %s lexima#expand(%s, ':')",
                  \ a:rule.char,
                  \ string(lexima#string#to_mappable(a:rule.char))
                  \ )
  endif
endfunction

function! lexima#cmdmode#clear_rules()
  for c in keys(s:map_dict)
    execute "cunmap " . c
  endfor
  let s:map_dict = {}
endfunction

function! lexima#cmdmode#define_altanative_key(char, mapping)
  execute printf("cnoremap <expr> %s lexima#cmdmode#_expand(%s)",
               \ a:char,
               \ string(lexima#string#to_mappable(a:mapping))
               \ )
endfunction

function! lexima#cmdmode#_expand(char) abort
  let char = lexima#string#to_upper_specialkey(a:char)
  let map = s:map_dict[char]
  let prehook = lexima#string#to_inputtable(
  \ type(map.prehook) == v:t_func ? call(map.prehook, [a:char]) : map.prehook
  \ )
  let posthook = lexima#string#to_inputtable(
  \ type(map.posthook) == v:t_func ? call(map.posthook, [a:char]) : map.posthook
  \ )
  return prehook .. s:input_impl(char) .. posthook
endfunction

function! s:input_impl(char) abort
  let char = a:char
  let pos = getcmdpos()
  let cmdline = getcmdline()
  let rule = s:find_rule(char)
  if rule == {}
    if char == '<ESC>'
      return lexima#string#to_inputtable('<C-C>')
    endif
    return lexima#string#to_inputtable(char)
  else
    let final_input = ''
    if has_key(rule, 'leave')
      if type(rule.leave) ==# type(0)
        let final_input .= repeat("\<Right>", rule.leave)
      elseif type(rule.leave) ==# type('')
        let matchidx = match(cmdline[pos-1:-1], lexima#string#to_inputtable(rule.leave))
        if matchidx ==# -1
          let final_input .= char
        else
          let final_input .= repeat("\<Right>", matchidx + 1)
        endif
      else
        throw 'lexima: Not applicable rule (' . string(rule) . ')'
      endif
    endif
    if has_key(rule, 'delete')
      if type(rule.delete) ==# type(0)
        let final_input .= repeat("\<Del>", rule.delete)
      elseif type(rule.delete) ==# type('')
        let matchidx = match(cmdline[pos-1:-1], lexima#string#to_inputtable(rule.leave))
        if matchidx ==# -1
          let final_input .= char
        else
          let final_input .= repeat("\<Del>", matchidx + 1)
        endif
      endif
    endif
    let final_input .= rule.input . rule.input_after
    return lexima#string#to_inputtable(final_input) . repeat("\<Left>", len(lexima#string#to_inputtable(rule.input_after)))
  endif
endfunction

function! s:find_rule(char) abort
  let pos = getcmdpos()
  let cmdline = getcmdline()
  let [precursor, postcursor] = lexima#string#take_many(cmdline, pos-1)
  let cmdtype = getcmdtype()
  let rules = lexima#cmdmode#get_map_rules(a:char)
  for rule in rules
    if rule.mode =~# 'c' || rule.mode =~# cmdtype
      if rule.char ==# a:char
        let rule_at = substitute(rule.at, '\\%#\|$', s:magic_cursor_string, '')
        let cmdline_with_cursor = (precursor .. s:magic_cursor_string .. postcursor)
        if cmdline_with_cursor =~# rule_at
          return rule
        endif
      endif
    endif
  endfor
  return {}
endfunction

function! lexima#cmdmode#_priority_order(rule1, rule2)
  let ft1 = !empty(a:rule1.filetype)
  let ft2 = !empty(a:rule2.filetype)
  if ft1 && !ft2
    return 1
  elseif ft2 && !ft1
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
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
