let s:suite = themis#suite('lexima')

function! s:suite.__defaults__()
  let defaults = themis#suite('default')

  function! defaults.before_each()
    %delete _
  endfunction

  function! defaults.automatically_inputs_pair_parentheses()
    execute "normal aHOGE(FUGA(PIYO\<Esc>"
    call Expect('HOGE(FUGA(PIYO))').to_be_displayed()
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
