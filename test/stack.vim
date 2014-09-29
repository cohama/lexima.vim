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

  function! new_stack.can_pop_but_nothing_returned()
    call Expect(s:stack.pop(100)).to_equal('')
    call s:stack.push('b')
    call Expect(s:stack.pop(2)).to_equal('b')
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

  function! new_stack.can_get_count_of_items()
    call s:stack.push('foo')
    call s:stack.push('bar')
    call s:stack.push('buz')
    call Expect(s:stack.count()).to_equal(9)
  endfunction

endfunction

function! s:suite.__event__()
  let onchange = themis#suite('on change event')

  function! OnChangeFn()
    let s:change_count += 1
  endfunction

  function onchange.before()
    let s:stack = lexima#charstack#new()
    let s:change_count = 0
    let s:stack.on_change = function('OnChangeFn')
  endfunction

  function! onchange.after()
    unlet s:stack
    unlet s:change_count
    delfunction OnChangeFn
  endfunction

  function! onchange.is_called_on_pushed_andor_popped()
    call s:stack.push('a')
    call s:stack.peek(1)
    call s:stack.pop(1)
    call Expect(s:change_count).to_equal(2)
  endfunction

endfunction
