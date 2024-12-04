let s:save_cpo = &cpo
set cpo&vim

let s:cr_key = '<CR>'

function! lexima#endwise_rule#make()
  let rules = []
  " vim
  for at in ['fu', 'fun', 'func', 'funct', 'functi', 'functio', 'function', 'if', 'wh', 'whi', 'whil', 'while', 'for', 'try', 'def']
    call add(rules, lexima#endwise_rule#make_rule('^\s*' . at . '\>.*\%#$', 'end' . at, 'vim', []))
  endfor

  for at in ['aug', 'augroup']
    call add(rules, lexima#endwise_rule#make_rule('^\s*' . at . '\s\+.\+\%#$', at . ' END', 'vim', []))
  endfor

  " ruby
  call add(rules, lexima#endwise_rule#make_rule('^\s*\%(module\|def\|class\|if\|unless\|for\|while\|until\|case\)\>\%(.*[^.:@$]\<end\>\)\@!.*\%#$', 'end', 'ruby', []))
  call add(rules, lexima#endwise_rule#make_rule('^\s*\%(begin\)\s*\%#$', 'end', 'ruby', []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!do\%(\s*|.*|\)\?\s*\%#$', 'end', 'ruby', []))
  call add(rules, lexima#endwise_rule#make_rule('\<\%(if\|unless\)\>.*\%#$', 'end', 'ruby', 'rubyConditionalExpression'))

  " elixir
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!do\s*\%#$', 'end', 'elixir', []))

  " sh
  call add(rules, lexima#endwise_rule#make_rule('^\s*if\>.*\%#$', 'fi', ['sh', 'zsh'], []))
  call add(rules, lexima#endwise_rule#make_rule('^\s*case\>.*\%#$', 'esac', ['sh', 'zsh'], []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!do\>.*\%#$', 'done', ['sh', 'zsh'], []))

  " julia
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!\<\%(module\|struct\|function\|if\|for\|while\|do\|let\|macro\)\>\%(.*\<end\>\)\@!.*\%#$', 'end', 'julia', []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!\s*\<\%(begin\|try\|quote\)\s*\%#$', 'end', 'julia', []))

  " lua
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*--.*\)\@<!\<function\>\%(.*\<end\>\)\@!.*\%#$', 'end', 'lua', []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*--.*\)\@<!\<do\s*\%#$', 'end', 'lua', []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*--.*\)\@<!\<then\s*\%#$', 'end', 'lua', []))

  return rules
endfunction

function! lexima#endwise_rule#make_rule(at, end, filetype, syntax)
  return {
  \ 'char': '<CR>',
  \ 'input': s:cr_key,
  \ 'input_after': '<CR>' . a:end,
  \ 'at': a:at,
  \ 'except': '\C\v^(\s*)\S.*%#\n%(%(\s*|\1\s.+)\n)*\1' . a:end,
  \ 'filetype': a:filetype,
  \ 'syntax': a:syntax,
  \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
