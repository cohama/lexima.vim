let s:save_cpo = &cpo
set cpo&vim

let s:L = lexima#vital().L

let s:map_dict = {}

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

function! lexima#cmdmode#add_rules(rule)
  " Expect a:rule to be regularized.
  if has_key(s:map_dict, a:rule.char)
    let newchar_flg = 0
  else
    let s:map_dict[a:rule.char] = {
    \ 'rules': {
    \     '_': lexima#sortedlist#new([], function('lexima#cmdmode#_priority_order'))
    \   },
    \ 'prehooks': [],
    \ 'posthooks': [],
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
  let prehooks = lexima#string#to_inputtable(join(map.prehooks, ''))
  let posthooks = lexima#string#to_inputtable(join(map.posthooks, ''))
  let pos = getcmdpos()
  let cmdline = getcmdline()
  let [precursor, postcursor] = lexima#string#take_many(cmdline, pos-1)
  let rule = s:find_rule(char)
  if rule == {}
    return lexima#string#to_inputtable(char)
  else
    if has_key(rule, 'leave')
      if type(rule.leave) ==# type(0)
        let input = repeat("\<Right>", rule.leave)
      elseif type(rule.leave) ==# type('')
        let matchidx = match(cmdline[pos-1:-1], lexima#string#to_inputtable(rule.leave))
        if matchidx ==# -1
          let input = a:char
        else
          let input = repeat("\<Right>", matchidx + 1)
        endif
      else
        throw 'lexima: Not applicable rule (' . string(rule) . ')'
      endif
      let input_after = ''
    else
      let input = rule.input
      if has_key(rule, 'delete')
        let input .= repeat("\<Del>", rule.delete)
      endif
      let input_after = rule.input_after
    endif
    return lexima#string#to_inputtable(input) . lexima#string#to_inputtable(input_after) . repeat("\<Left>", len(lexima#string#to_inputtable(input_after)))
  endif
endfunction

function! s:find_rule(char)
  let pos = getcmdpos()
  let cmdline = getcmdline()
  let [precursor, postcursor] = lexima#string#take_many(cmdline, pos-1)
  let cmdtype = getcmdtype()
  let rules = lexima#cmdmode#get_map_rules(a:char)
  for rule in rules
    if rule.mode =~# 'c' || rule.mode =~# cmdtype
      if rule.char ==# a:char
        let [pre_at, post_at] = map(split(rule.at, '\\%#', 1) + ['', ''], 'v:val . "$"')[0:1]
        if precursor =~# pre_at && postcursor =~# post_at
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
