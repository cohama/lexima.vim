let s:suite = themis#suite('stack')

function! s:suite.__new_stack__()
  let new_stack = themis#suite('new stack')

  function! new_stack.before_each()
    let s:stack = lexima#charstack#new()
  endfunction

  function! new_stack.after_each()
    unlet s:stack
  endfunction

  function! new_stack.can_push_one_element()
    call s:stack.push('a')
    call Expect(s:stack.is_empty()).to_be_false()
  endfunction

  function! new_stack.can_push_and_pop_one_element()
    call s:stack.push('b')
    call Expect(s:stack.pop(1)).to_equal('b')
    call Expect(s:stack.is_empty()).to_be_true()
  endfunction

  function! new_stack.can_pop_two_element_sequentially()
    call s:stack.push('foo')
    call s:stack.push('bar')
    call Expect(s:stack.pop(2)).to_equal('ba')
    call Expect(s:stack.is_empty()).to_be_false()
    call Expect(s:stack.pop_all()).to_equal('rfoo')
    call Expect(s:stack.is_empty()).to_be_true()
  endfunction

  function! new_stack.can_pop_all()
    call s:stack.push('abc')
    call s:stack.push('def')
    call s:stack.push('ghi')
    call Expect(s:stack.pop_all()).to_equal('ghidefabc')
    call Expect(s:stack.is_empty()).to_be_true()
  endfunction

  function! new_stack.can_push_and_pop_one_element()
    call s:stack.push('b')
    call Expect(s:stack.peek()).to_equal('b')
    call Expect(s:stack.is_empty()).to_be_false()
  endfunction

  function! new_stack.can_peek_two_element_sequentially()
    call s:stack.push('foo')
    call s:stack.push('bar')
    call s:stack.push('buz')
    call Expect(s:stack.peek(2)).to_equal('bu')
    call Expect(s:stack.is_empty()).to_be_false()
    call Expect(s:stack.pop(2)).to_equal('bu')
    call Expect(s:stack.is_empty()).to_be_false()
  endfunction

endfunction
