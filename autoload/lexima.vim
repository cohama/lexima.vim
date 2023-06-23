let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#lexima#new()
let s:L = s:V.import('Data.List')
let s:S = s:V.import('Data.String')
let s:B = s:V.import('Vim.Buffer')

let g:lexima_no_default_rules = get(g:, 'lexima_no_default_rules', 0)
let g:lexima_no_map_to_escape = get(g:, 'lexima_no_map_to_escape', 0)
let g:lexima_enable_basic_rules = get(g:, 'lexima_enable_basic_rules', 1)
let g:lexima_enable_newline_rules = get(g:, 'lexima_enable_newline_rules', 1)
let g:lexima_enable_space_rules = get(g:, 'lexima_enable_space_rules', 1)
let g:lexima_enable_endwise_rules = get(g:, 'lexima_enable_endwise_rules', 1)
if exists('g:lexima_nvim_accept_pum_with_enter')
  echohl WarningMsg
  echom 'lexima: g:lexima_nvim_accept_pum_with_enter is deprecated. Use g:lexima_accept_pum_with_enter instead.'
  echohl None
  let g:lexima_accept_pum_with_enter = g:lexima_nvim_accept_pum_with_enter
endif
let g:lexima_accept_pum_with_enter = get(g:, 'lexima_accept_pum_with_enter', has('nvim'))
let g:lexima_ctrlh_as_backspace = get(g:, 'lexima_ctrlh_as_backspace', 0)
let g:lexima_disable_on_nofile = get(g:, 'lexima_disable_on_nofile', 0)
let g:lexima_disable_abbrev_trigger = get(g:, 'lexima_disable_abbrev_trigger', 0)
let g:lexima_disable_auto_mapping = get(g:, 'lexima_disable_auto_mapping', 0)

let s:lexima_vital = {
\ 'L' : s:L,
\ 'S' : s:S,
\ 'B' : s:B
\ }

let s:default_rule = {
\ 'at': '\%#',
\ 'filetype': [],
\ 'syntax': [],
\ 'mode': 'i',
\ 'input_after': '',
\ 'priority': 0,
\ }

let g:lexima#default_rules = [
\ {'char': '(', 'input_after': ')'},
\ {'char': '(', 'at': '\\\%#'},
\ {'char': ')', 'at': '\%#)', 'leave': 1},
\ {'char': '<BS>', 'at': '(\%#)', 'delete': 1},
\ {'char': '{', 'input_after': '}'},
\ {'char': '}', 'at': '\%#}', 'leave': 1},
\ {'char': '<BS>', 'at': '{\%#}', 'delete': 1},
\ {'char': '[', 'input_after': ']'},
\ {'char': '[', 'at': '\\\%#'},
\ {'char': ']', 'at': '\%#]', 'leave': 1},
\ {'char': '<BS>', 'at': '\[\%#\]', 'delete': 1},
\ ]
let g:lexima#default_rules += [
\ {'char': '"', 'input_after': '"'},
\ {'char': '"', 'at': '\%#"', 'leave': 1},
\ {'char': '"', 'at': '\\\%#'},
\ {'char': '"', 'at': '^\s*\%#', 'filetype': 'vim'},
\ {'char': '"', 'at': '\%#\s*$', 'filetype': 'vim'},
\ {'char': '<BS>', 'at': '"\%#"', 'delete': 1},
\ {'char': '"', 'at': '""\%#', 'input_after': '"""'},
\ {'char': '"', 'at': '\%#"""', 'leave': 3},
\ {'char': '<BS>', 'at': '"""\%#"""', 'input': '<BS><BS><BS>', 'delete': 3},
\ {'char': "'", 'input_after': "'"},
\ {'char': "'", 'at': '\%#''', 'leave': 1},
\ {'char': "'", 'at': '\w\%#''\@!'},
\ {'char': "'", 'at': '\\\%#'},
\ {'char': "'", 'at': '\\\%#', 'leave': 1, 'filetype': ['vim', 'sh', 'csh', 'ruby', 'tcsh', 'zsh']},
\ {'char': "'", 'filetype': ['haskell', 'lisp', 'clojure', 'ocaml', 'reason', 'scala', 'rust']},
\ {'char': '<BS>', 'at': "'\\%#'", 'delete': 1},
\ {'char': "'", 'at': "''\\%#", 'input_after': "'''"},
\ {'char': "'", 'at': "\\%#'''", 'leave': 3},
\ {'char': '<BS>', 'at': "'''\\%#'''", 'input': '<BS><BS><BS>', 'delete': 3},
\ {'char': '`', 'input_after': '`'},
\ {'char': '`', 'at': '\%#`', 'leave': 1},
\ {'char': '<BS>', 'at': '`\%#`', 'delete': 1},
\ {'char': '`', 'filetype': ['ocaml', 'reason']},
\ {'char': '`', 'at': '``\%#', 'input_after': '```'},
\ {'char': '`', 'at': '\%#```', 'leave': 3},
\ {'char': '<BS>', 'at': '```\%#```', 'input': '<BS><BS><BS>', 'delete': 3},
\ ]

let g:lexima#newline_rules = [
\ {'char': '<CR>', 'at': '(\%#)', 'input_after': '<CR>'},
\ {'char': '<CR>', 'at': '(\%#$', 'input_after': '<CR>)', 'except': '\C\v^(\s*)\S.*%#\n%(%(\s*|\1\s.+)\n)*\1\)'},
\ {'char': '<CR>', 'at': '{\%#}', 'input_after': '<CR>'},
\ {'char': '<CR>', 'at': '{\%#$', 'input_after': '<CR>}', 'except': '\C\v^(\s*)\S.*%#\n%(%(\s*|\1\s.+)\n)*\1\}'},
\ {'char': '<CR>', 'at': '\[\%#]', 'input_after': '<CR>'},
\ {'char': '<CR>', 'at': '\[\%#$', 'input_after': '<CR>]', 'except': '\C\v^(\s*)\S.*%#\n%(%(\s*|\1\s.+)\n)*\1\]'},
\ {'char': '<CR>', 'at': '^```\(\S*\)\%#```', 'input': '<CR>', 'input_after': '<CR>'},
\ ]

let g:lexima#space_rules = [
\ {'char': '<Space>', 'at': '(\%#)', 'input_after': '<Space>'},
\ {'char': ')', 'at': '\%# )', 'leave': 2},
\ {'char': '<BS>', 'at': '( \%# )', 'delete': 1},
\ {'char': '<Space>', 'at': '{\%#}', 'input_after': '<Space>'},
\ {'char': '}', 'at': '\%# }', 'leave': 2},
\ {'char': '<BS>', 'at': '{ \%# }', 'delete': 1},
\ {'char': '<Space>', 'at': '\[\%#]', 'input_after': '<Space>'},
\ {'char': ']', 'at': '\%# ]', 'leave': 2},
\ {'char': '<BS>', 'at': '\[ \%# ]', 'delete': 1},
\ ]

function! lexima#vital()
  return s:lexima_vital
endfunction

function! lexima#set_default_rules()
  call lexima#clear_rules()
  if g:lexima_enable_basic_rules
    for rule in g:lexima#default_rules
      call lexima#add_rule(rule)
    endfor
  endif
  if g:lexima_enable_newline_rules
    for rule in g:lexima#newline_rules
      call lexima#add_rule(rule)
    endfor
  endif
  if g:lexima_enable_space_rules
    for rule in g:lexima#space_rules
      call lexima#add_rule(rule)
    endfor
  endif
  if g:lexima_enable_endwise_rules
    for rule in lexima#endwise_rule#make()
      call lexima#add_rule(rule)
    endfor
  endif
  if g:lexima_ctrlh_as_backspace
    call lexima#insmode#define_altanative_key('<C-h>', '<BS>')
  endif
endfunction

function! lexima#clear_rules()
  call lexima#insmode#clear_rules()
  call lexima#cmdmode#clear_rules()
endfunction

function! lexima#add_rule(rule)
  let rule = s:regularize(a:rule)
  if rule.mode =~# 'i'
    call lexima#insmode#add_rules(rule)
  endif
  if rule.mode =~# '[c:/?]'
    call lexima#cmdmode#add_rules(rule)
  endif
endfunction

function! lexima#expand(char, mode) abort
  if a:mode ==# 'i'
    return lexima#insmode#_expand(a:char)
  elseif a:mode ==# ':'
    return lexima#cmdmode#_expand(a:char)
  else
    throw 'lexima: Illegal `mode` parameter. (' . a:mode . ')'
  endif
endfunction

function! lexima#define_mappings() abort
  call lexima#define_mappings_without([])
endfunction

function! lexima#define_mappings_without(ignore_chars) abort
  call lexima#insmode#_define_mappings_without(a:ignore_chars)
  call lexima#cmdmode#_define_mappings_without(a:ignore_chars)
endfunction

function! s:regularize(rule)
  let reg_rule = extend(deepcopy(a:rule), s:default_rule, 'keep')
  if type(reg_rule.filetype) !=# type([])
    let reg_rule.filetype = [reg_rule.filetype]
  endif
  if type(reg_rule.syntax) !=# type([])
    let reg_rule.syntax = [reg_rule.syntax]
  endif
  if !has_key(reg_rule, 'input')
    if has_key(reg_rule, 'leave')
      let reg_rule.input = ''
    else
      let reg_rule.input = reg_rule.char
    endif
  endif
  let reg_rule.char = lexima#string#to_upper_specialkey(reg_rule.char)
  return reg_rule
endfunction

function! lexima#init()
endfunction

if !g:lexima_no_default_rules
  call lexima#set_default_rules()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
