let s:suite = themis#suite('lexima')
let s:expect = themis#helper('expect')

function! s:suite.__defaults__()
  let defaults = themis#suite('default')

  function! defaults.before_each()
    %delete _
  endfunction

  function! defaults.automatically_inputs_pair_parentheses()
    execute "normal aHOGE(FUGA(PIYO\<Esc>"
    call s:expect(getline(1)).to_equal('HOGE(FUGA(PIYO))')
  endfunction

  function! defaults.can_repeat_with_dots()
    execute "normal oHOGE(FUGA(PIYO\<Esc>"
    normal! ..
    call s:expect(getline(1, '$')).to_equal(['', 'HOGE(FUGA(PIYO))', 'HOGE(FUGA(PIYO))', 'HOGE(FUGA(PIYO))'])
  endfunction

  function! defaults.can_input_closing_parenthesis()
    execute "normal i)\<Esc>"
    call s:expect(getline(1)).to_equal(')')
  endfunction

  function! defaults.can_leave_at_end_of_parenthesis()
    execute "normal iHOGE(FUGA(PIYO))\<Esc>"
    call s:expect(getline(1, '$')).to_equal(['HOGE(FUGA(PIYO))'])
  endfunction

  function! defaults.can_leave_at_end_of_parenthesis2()
    execute "normal iHOGE(FUGA(PIYO), x(y\<Esc>"
    call s:expect(getline(1)).to_equal('HOGE(FUGA(PIYO), x(y))')
  endfunction

  function! defaults.with_leave_can_repeat_with_dots()
    execute "normal oHOGE(FUGA(PIYO), x(y\<Esc>"
    normal! ..
    call s:expect(getline(1, '$')).to_equal(['', 'HOGE(FUGA(PIYO), x(y))', 'HOGE(FUGA(PIYO), x(y))', 'HOGE(FUGA(PIYO), x(y))', ])
  endfunction

  function! defaults.with_leave_can_repeat_with_dots2()
    for i in range(1, 3)
      call setline(i, '12345')
    endfor
    normal! gg2|
    execute "normal aHOGE(FUGA(PIYO), x(y\<Esc>"
    normal! j0.
    normal! j$.
    call s:expect(getline(1, '$')).to_equal(['12HOGE(FUGA(PIYO), x(y))345', '1HOGE(FUGA(PIYO), x(y))2345', '12345HOGE(FUGA(PIYO), x(y))', ])
  endfunction

endfunction
