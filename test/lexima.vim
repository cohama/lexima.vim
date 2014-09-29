let s:suite = themis#suite('lexima')

function! s:suite.__defaults__()
  let defaults = themis#suite('default')

  function! defaults.before_each()
    %delete _
  endfunction

  function! defaults.automatically_inputs_pair_parentheses()
    execute "normal aHOGE(FUGA(PIYO\<Esc>"
    call Expect(['HOGE(FUGA(PIYO))']).to_be_displayed()
    execute "normal I(\<Esc>"
    call Expect(['()HOGE(FUGA(PIYO))']).to_be_displayed()
  endfunction

  function! defaults.can_repeat_with_dots()
    execute "normal oHOGE(FUGA(PIYO\<Esc>"
    normal! ..
    call Expect(['', 'HOGE(FUGA(PIYO))', 'HOGE(FUGA(PIYO))', 'HOGE(FUGA(PIYO))']).to_be_displayed()
  endfunction

  function! defaults.can_input_closing_parenthesis()
    execute "normal i)\<Esc>"
    call Expect(')').to_be_displayed()
  endfunction

  function! defaults.can_leave_at_end_of_parenthesis()
    execute "normal iHOGE(FUGA(PIYO))\<Esc>"
    call Expect(['HOGE(FUGA(PIYO))']).to_be_displayed()
  endfunction

  function! defaults.can_leave_at_end_of_parenthesis2()
    execute "normal iHOGE(FUGA(PIYO), x(y\<Esc>"
    call Expect('HOGE(FUGA(PIYO), x(y))').to_be_displayed()
  endfunction

  function! defaults.with_leave_can_repeat_with_dots()
    execute "normal oHOGE(FUGA(PIYO), x(y\<Esc>"
    normal! ..
    call Expect(['', 'HOGE(FUGA(PIYO), x(y))', 'HOGE(FUGA(PIYO), x(y))', 'HOGE(FUGA(PIYO), x(y))', ]).to_be_displayed()
  endfunction

  function! defaults.with_leave_can_repeat_with_dots2()
    for i in range(1, 3)
      call setline(i, '12345')
    endfor
    normal! gg2|
    execute "normal aHOGE(FUGA(PIYO), x(y\<Esc>"
    normal! j0.
    normal! j$.
    call Expect(['12HOGE(FUGA(PIYO), x(y))345', '1HOGE(FUGA(PIYO), x(y))2345', '12345HOGE(FUGA(PIYO), x(y))', ]).to_be_displayed()
  endfunction

  function! defaults.can_repeat_if_CR_input()
    execute "normal oHOGE(\<CR>\<Esc>"
    normal! ..
    call Expect(['', 'HOGE(', ')', 'HOGE(', ')', 'HOGE(', ')']).to_be_displayed()
  endfunction

  function! defaults.can_repeat_if_CR_input_with_set_smartindent()
    setlocal smartindent
    execute "normal oHOGE(\<CR>\<Esc>"
    normal! ..
    call Expect(['', 'HOGE(', ')', 'HOGE(', ')', 'HOGE(', ')']).to_be_displayed()
    setlocal smartindent&
  endfunction

  function! defaults.automatically_inputs_pair_braces_with_newline()
    execute "normal aHOGE({\<CR>FUGA{\<CR>PIYO{\<CR>\<Esc>"
    call Expect(['HOGE({', 'FUGA{', 'PIYO{', '', '}', '}', '})']).to_be_displayed()
  endfunction

  function! defaults.automatically_inputs_pair_braces_with_newline_and_set_smartindent()
    setlocal smartindent
    execute "normal aHOGE({\<CR>FUGA{\<CR>PIYO{\<CR>\<Esc>"
    call Expect(['HOGE({', "\tFUGA{", "\t\tPIYO{", '',  "\t\t}", "\t}", '})']).to_be_displayed()
    setlocal smartindent&
  endfunction

  function! defaults.automatically_inputs_pair_braces_with_newline_and_set_indentexpr()
    setlocal ft=ruby et sw=2
    execute "normal amodule Hoge\<CR>def piyo\<CR>foo {\<CR>\<Esc>"
    call Expect(['module Hoge', '  def piyo', '    foo {', '', '    }']).to_be_displayed()
    setlocal ft= et& sw&
  endfunction

  function! defaults.can_move_the_cursor()
    execute "normal aHOGE(\"FUGA\<Right>\<Right>\<Esc>"
    call Expect(['HOGE("FUGA")']).to_be_displayed()
  endfunction

endfunction

" function! s:suite.__leave_rules__()
"   let leave_rule = themis#suite('leave rules')

"   function! leave_rule.before()
"     call lexima#clear_rules()
"     call lexima#add_rule({'char': '(', 'input_after': ')'})
"     call lexima#add_rule({'char': '*', 'at': '(\%#)', 'input_after': '*'})
"     call lexima#add_rule({'char': '*', 'at': '\%#\*)', 'leave': 1})
"     call lexima#add_rule({'char': ')', 'at': '\%#\*)', 'leave': 2})
"   endfunction

"   function! leave_rule.before_each()
"     %delete _
"   endfunction

"   function! leave_rule.can_leave_one()
"     execute "normal i(**;\<Esc>"
"     call Expect(['(**;)']).to_be_displayed()
"   endfunction

"   function! leave_rule.can_leave_two()
"     execute "normal i(*);\<Esc>"
"     call Expect(['(**);']).to_be_displayed()
"   endfunction

" endfunction

function! s:suite.__leave_rules__()
  let leave_rule = themis#suite('leave rules')

  function! leave_rule.before()
    new
    setlocal nocindent smartindent
    only!
  endfunction

  function! leave_rule.before_each()
    call lexima#clear_rules()
    call lexima#add_rule({'char': '{', 'input_after': '}'})
    call lexima#add_rule({'char': '*', 'at': '{\%#}', 'input_after': '*'})
    %delete _
  endfunction

  function! leave_rule.can_leave_one()
    call lexima#add_rule({'char': '*', 'at': '\%#\*}', 'leave': 1})
    execute "normal i{**;\<Esc>"
    call Expect(['{**;}']).to_be_displayed()
  endfunction

  function! leave_rule.can_leave_two()
    call lexima#add_rule({'char': '}', 'at': '\%#\*}', 'leave': 2})
    execute "normal i{*};\<Esc>"
    call Expect(['{**};']).to_be_displayed()
  endfunction

  function! leave_rule.can_leave_till_specified_char()
    call lexima#add_rule({'char': '}', 'at': '\%#\*}', 'leave': '}'})
    execute "normal i{*};\<Esc>"
    call Expect(['{**};']).to_be_displayed()
  endfunction

  function! leave_rule.can_leave_over_cr()
    call lexima#add_rule({'char': '<CR>', 'at': '{\%#}', 'input_after': '<CR>'})
    call lexima#add_rule({'char': '}', 'leave': 1})
    execute "normal i{\<CR>;}\<Esc>"
    call Expect(['{', "\t;", '}']).to_be_displayed()
  endfunction

  function! leave_rule.can_leave_till_specified_char_over_cr()
    call lexima#add_rule({'char': '<CR>', 'at': '{\%#}', 'input_after': '<CR>'})
    call lexima#add_rule({'char': '}', 'leave': '}'})
    execute "normal i{\<CR>;}\<Esc>"
    call Expect(['{', "\t;", '}']).to_be_displayed()
  endfunction

  function! leave_rule.can_leave_till_specified_char_over_cr()
    call lexima#add_rule({'char': '<CR>', 'at': '{\%#}', 'input_after': '<CR>'})
    call lexima#add_rule({'char': '}', 'leave': '}'})
    execute "normal o{\<CR>{\<CR>hoge{}}\<Esc>"
    normal! .
    call Expect(['', '{', "\t{", "\t\thoge{}", "\t}", '}', '{', "\t{", "\t\thoge{}", "\t}", '}']).to_be_displayed()
  endfunction

  function! leave_rule.can_leave_till_end_of_line()
    call lexima#add_rule({'char': '"', 'input_after': '"'})
    call lexima#add_rule({'char': '<CR>', 'at': '{\%#}', 'input_after': '<CR>'})
    call lexima#add_rule({'char': '}', 'leave': '}'})
    execute "normal o{\<CR>{\<CR>hoge{\"foo{\<C-r>=lexima#leave_till_eol('')\<CR>;\<Esc>"
    call Expect(['', '{', "\t{", "\t\thoge{\"foo{}\"};", "\t}", '}']).to_be_displayed()
    normal! .
    call Expect(['', '{', "\t{", "\t\thoge{\"foo{}\"};", "\t}", '}', '{', "\t{", "\t\thoge{\"foo{}\"};", "\t}", '}']).to_be_displayed()
  endfunction

endfunction

function! s:suite.__filetype_rules__()
  let ft_rule = themis#suite('filetype rules')

  function! ft_rule.before()
    call lexima#clear_rules()
    let s:save_default_rules = g:lexima#default_rules
    let g:lexima_no_default_rules = 1
    call lexima#add_rule({'char': '(', 'input_after': ')'})
    call lexima#add_rule({'char': '(', 'input_after': 'Ruby!)', 'filetype': 'ruby'})
    call lexima#add_rule({'char': '(', 'input_after': 'Java script?)', 'filetype': 'javascript'})
  endfunction

  function! ft_rule.before_each()
    only!
    enew!
  endfunction

  function! ft_rule.is_triggered_in_suitable_filetype()
    execute "normal i(\<Esc>"
    call Expect(['()']).to_be_displayed()
    enew!
    setlocal filetype=ruby
    execute "normal i(\<Esc>"
    call Expect(['(Ruby!)']).to_be_displayed()
    enew!
    setlocal filetype=javascript
    execute "normal i(\<Esc>"
    call Expect(['(Java script?)']).to_be_displayed()
  endfunction

  function! ft_rule.falls_back_to_default_rule()
    setlocal filetype=ocaml
    execute "normal i(\<Esc>"
    call Expect(['()']).to_be_displayed()
  endfunction

endfunction

function! s:suite.__syntax_rules__()
  let syn_rule = themis#suite('syntax rules')

  function! syn_rule.before()
    call lexima#clear_rules()
    let s:save_default_rules = g:lexima#default_rules
    let g:lexima_no_default_rules = 1
    call lexima#add_rule({'char': '"', 'input_after': '"'})
    call lexima#add_rule({'char': '%', 'input': '%%', 'syntax': 'String'})
    vnew
    only!
    setlocal filetype=vim
  endfunction

  function! syn_rule.before_each()
    %delete _
  endfunction

  function! syn_rule.is_triggered_in_suitable_syntax()
    execute "normal ilet x = %\"%\<Esc>"
    call Expect(['let x = %"%%"']).to_be_displayed()
  endfunction

endfunction
