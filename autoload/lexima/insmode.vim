let s:save_cpo = &cpo
set cpo&vim

let s:B = lexima#vital().B
let s:L = lexima#vital().L

let s:pass_through_input_stack = lexima#charstack#new()  " can use arrow key e.g. ()<C-g>U<Left>
let s:lazy_input_stack = lexima#charstack#new()  " cannot use arrow key e.g. {<CR>. It will be input on press <Esc>.

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
  if lexima#string#to_inputtable(a:char) !~ '.*\k$'
  \ && (!g:lexima_disable_abbrev_trigger && !get(b:, 'lexima_disable_abbrev_trigger', 0))
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
    if a:rule.char == '<CR>' && g:lexima_accept_pum_with_enter
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
  let fallback = lexima#string#to_inputtable(a:char)
  if !has_key(s:map_dict, a:char) || mode() !=# 'i'
    return fallback
  endif
  let map = s:map_dict[a:char]
  let prehook = lexima#string#to_inputtable(
  \ (type(map.prehook)) ==# type(function("tr")) ? call(map.prehook, [a:char]) : map.prehook
  \ )
  let posthook = lexima#string#to_inputtable(
  \ (type(map.posthook)) ==# type(function("tr")) ? call(map.posthook, [a:char]) : map.posthook
  \ )
  return printf("%s\<C-r>=lexima#insmode#_map_impl(%s)\<CR>%s",
              \ prehook,
              \ string(a:char),
              \ posthook
              \ )
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

function! lexima#insmode#_map_impl(char) abort
  let fallback = lexima#string#to_inputtable(a:char)
  if g:lexima_disable_on_nofile && &buftype ==# 'nofile'
    return fallback
  endif
  if exists('b:lexima_disabled') && b:lexima_disabled
    return fallback
  endif
  let [rule, at_start_pos] = s:find_rule(a:char)
  if rule == {}
    return fallback
  else
    let final_input = ''
    if has_key(rule, 'leave')
      if type(rule.leave) ==# type('')
        let final_input .= lexima#insmode#leave_till(rule.leave, lexima#string#to_mappable(a:char))
      elseif type(rule.leave) ==# type(0)
        let final_input .= lexima#insmode#leave(rule.leave, lexima#string#to_mappable(a:char))
      else
        throw 'lexima: Not applicable rule (' . string(rule) . ')'
      endif
    endif
    if has_key(rule, 'delete')
      if type(rule.delete) ==# type('')
        let final_input .= lexima#insmode#delete_till(rule.delete, lexima#string#to_mappable(a:char))
      elseif type(rule.delete) ==# type(0)
        let final_input .= lexima#insmode#delete(rule.delete, lexima#string#to_mappable(repeat("\<Del>", rule.delete)))
      else
        throw 'lexima: Not applicable rule (' . string(rule) . ')'
      endif
    endif
    if get(rule, 'with_submatch', 0)
      let searchlimit = max([0, line('.') - 20])
      let at_end_pos = searchpos(rule.at, 'bcWne', searchlimit)
      if at_end_pos == [0, 0]
        let at_end_pos = searchpos(rule.at, 'cWne', searchlimit)
        if at_end_pos == [0, 0]
          echoerr "Pattern not found. This is lexima's bug. Please report an issue with the following information."
          echoerr rule
        endif
      endif
      let context = join(getline(at_start_pos[0], at_end_pos[0]), "\n")[at_start_pos[1] - 1:at_end_pos[1]]
      let pattern = substitute(rule.at, '\\%#', '', '')
      let base_string = matchstr(context, pattern)
      let input = substitute(base_string, pattern, rule.input, '')
      let input_after = substitute(base_string, pattern, rule.input_after, '')
    else
      let input = rule.input
      let input_after = rule.input_after
    endif
    " Delay calling input_impl
    " so that 'delete' and 'leave' always perform BEFORE 'input'.
    " Tips: Unlike input_impl, calling 'delete' and 'leave' offen have no side effects,
    " these return just a string such as <Del>, <C-g>U<Right> unless multiline
    let final_input .= printf('<C-r>=lexima#insmode#_input_impl(%s, %s)<CR>',
    \ string(lexima#string#to_mappable(input)),
    \ string(lexima#string#to_mappable(input_after))
    \ )
    return lexima#string#to_inputtable(final_input)
  endif
endfunction

function! s:find_rule(char)
  let syntax_chain = s:get_syntax_link_chain()
  let searchlimit = max([0, line('.') - 20])
  let rules = lexima#insmode#get_map_rules(a:char)
  for rule in rules
    let at_pos = searchpos(rule.at, 'bcWn', searchlimit)
    let excepted = has_key(rule, 'except') ?
    \              searchpos(rule.except, 'bcWn', searchlimit) !=# [0, 0] : 0
    if at_pos !=# [0, 0] && !excepted
      if empty(rule.syntax)
        return [rule, at_pos]
      else
        for syn in syntax_chain
          if index(rule.syntax, syn) >=# 0
            return [rule, at_pos]
          endif
        endfor
      endif
    endif
  endfor
  return [{}, [0, 0]]
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

function! lexima#insmode#_input_impl(input, input_after) abort
  " 'input': 'AAA', 'input_after': 'BBB<CR>CCC'
  " This will be treated as the following
  " input: AAABBB<Left><Left><Left>
  " input_after: <CR>CCC
  let a_input = lexima#string#to_inputtable(a:input)
  let a_input_after = lexima#string#to_inputtable(a:input_after)
  let [first_line; after_lines] = split(a_input_after, "\r", 1)
  let input = s:input_oneline(a_input, first_line)
  if len(after_lines) == 0
    " 'pass through' means it can be used with <C-u>G
    call s:pass_through_input_stack.push(a_input_after)
    return input
  endif

  " Emulate inserting <CR> with setline() (or append()).
  " <CR> on AAA|BBB will be
  " setline(i, AAA)
  " setline(i + 1, BBB)
  let [bufnum, lnum, col, off] = getpos('.')
  let curline = getline('.')
  let precursor = curline[:col - 2]
  let postcursor = curline[col - 1:]
  call setline('.', precursor)
  let after_lines[-1] .= postcursor
  call append(lnum, after_lines)

  " handling indent
  for i in range(0, len(after_lines) - 1)
    let indent_depth = s:calc_indent_depth(lnum + i + 1)
    let indent = s:get_indent_chars(indent_depth)
    call setline(lnum + i + 1, indent . after_lines[i])  " fix indent
  endfor

  call setpos(".", [bufnum, lnum, col, off])

  " {|} => {<CR>|<CR>}
  " input: <Del><CR>
  " input_after: <CR>}
  " pass_through_input ('}' in above) will be moved to lazy_input_stack
  " This will be input by lexima#escape()
  let pass_through_input = s:pass_through_input_stack.pop_all()
  if match(postcursor, '\V\C\^' . pass_through_input) != -1
    let input = repeat(lexima#string#to_inputtable("<Del>"), strchars(pass_through_input))
    \ . input
    call s:pass_through_input_stack.push(first_line)
    call s:lazy_input_stack.push(a_input_after[len(first_line):] . pass_through_input)
    call setline('.', precursor . pass_through_input)
  endif

  return input
endfunction

function! s:input_oneline(input, input_after) abort
  return a:input . a:input_after . repeat(lexima#string#to_inputtable("<C-g>U<Left>"), strchars(a:input_after))
endfunction

function! s:calc_indent_depth(lnum) abort
  if &indentexpr ==# ''
    if &smartindent || &cindent
      return cindent(a:lnum)
    elseif &autoindent
      return indent(a:lnum - 1)
    else
      return 0
    endif
  else
    let v:lnum = a:lnum
    silent! let indent_depth = eval(&l:indentexpr)
    return indent_depth
  endif
endfunction

function! s:get_indent_chars(indent_depth) abort
  if &expandtab
    return repeat(' ', a:indent_depth)
  else
    return repeat("\t", a:indent_depth / &tabstop) . repeat(' ', a:indent_depth % &tabstop)
  endif
endfunction

function! lexima#insmode#try_leave(len) abort
  " Returns: [pass_through_input, lazy_input, is_failed]
  let error = "ERROR!!!"
  if s:pass_through_input_stack.is_empty() && s:lazy_input_stack.is_empty()
    return [error, error, 1]
  endif
  if a:len <= s:pass_through_input_stack.count()
    return [s:pass_through_input_stack.pop(a:len), "", 0]
  endif
  let lazy_input = s:lazy_input_stack.peek(a:len - s:pass_through_input_stack.count())
  let [bufnum, lnum, col, off] = getpos('.')
  let cr_count = len(split(lazy_input, "\r", 1)) - 1
  let will_input = substitute(
  \ substitute(s:pass_through_input_stack.peek_all() . lazy_input, '\', '\\\\', 'g'),
  \ "\r", '\\n\\s\\*', 'g')
  let illegal = search('\V\%#' . will_input, 'bcWn') ==# 0
  if illegal
    return [error, error, 1]
  endif
  for i in range(1, cr_count)
    call setline(lnum+i, substitute(getline(lnum+i), '\V\^\s\*', '', ''))
  endfor
  if cr_count !=# 0
    execute 'join! ' . (cr_count + 1)
  endif
  call setpos('.', [bufnum, lnum, col, off])
  let curline = getline('.')
  let leave_candidates_len = s:pass_through_input_stack.count()
  let lazy_input_len = strchars(lazy_input) - cr_count
  let [precursor, leave_candidates, lazy_candidates, postcursor] = lexima#string#take_many(curline, col-1, leave_candidates_len, lazy_input_len)
  call setline('.', precursor .  leave_candidates . postcursor)
  call s:lazy_input_stack.pop(strchars(lazy_input))
  return [s:pass_through_input_stack.pop_all(), lazy_input, 0]
endfunction

function! lexima#insmode#leave(len, fallback)
  let [pass_through_input, lazy_input, is_failed] = lexima#insmode#try_leave(a:len)
  if is_failed
    return lexima#string#to_inputtable(a:fallback)
  else
    return repeat(lexima#string#to_inputtable("<C-g>U<Right>"), strchars(pass_through_input)) . lazy_input
  endif
endfunction

function! lexima#insmode#leave_till(char, fallback)
  let input = s:pass_through_input_stack.peek_all() . s:lazy_input_stack.peek_all()
  let tilllen = match(input, a:char)
  if tilllen ==# -1
    return lexima#string#to_inputtable(a:fallback)
  else
    return lexima#insmode#leave(tilllen + len(a:char), a:fallback)
  endif
endfunction

function! lexima#insmode#leave_all(fallback)
  return lexima#insmode#leave(s:pass_through_input_stack.count() + s:lazy_input_stack.count(), a:fallback)
endfunction

function! lexima#insmode#leave_till_eol(fallback)
  return lexima#insmode#leave(s:pass_through_input_stack.count(), a:fallback)
endfunction

function! lexima#insmode#delete(len, fallback)
  let [pass_through_input, lazy_input, is_failed] = lexima#insmode#try_leave(a:len)
  if is_failed
    return lexima#string#to_inputtable(a:fallback)
  else
    return repeat(lexima#string#to_inputtable("<Del>"), strchars(pass_through_input))
  endif
endfunction

function! lexima#insmode#delete_till(char, fallback)
  let input = s:pass_through_input_stack.peek_all() . s:lazy_input_stack.peek_all()
  let tilllen = match(input, a:char)
  if tilllen ==# -1
    return lexima#string#to_inputtable(a:fallback)
  else
    return lexima#insmode#delete(tilllen + len(a:char), a:fallback)
  endif
endfunction

function! lexima#insmode#delete_till_eol(fallback)
  return lexima#insmode#delete(s:pass_through_input_stack.count(), a:fallback)
endfunction

function! lexima#insmode#delete_all(fallback)
  return lexima#insmode#delete(s:pass_through_input_stack.count() + s:lazy_input_stack.count(), a:fallback)
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
  call lexima#insmode#clear_stack()
  return ret
endfunction

function! lexima#insmode#clear_stack()
  if !s:pass_through_input_stack.is_empty()
    call s:pass_through_input_stack.pop_all()
  endif
  if !s:lazy_input_stack.is_empty()
    call s:lazy_input_stack.pop_all()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
