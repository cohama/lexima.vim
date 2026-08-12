let s:save_cpo = &cpo
set cpo&vim

let s:cr_key = '<CR>'

function! lexima#endwise_rule#make()
  let rules = []
  " vim
  for at in ['fu', 'fun', 'func', 'funct', 'functi', 'functio', 'function', 'wh', 'whi', 'whil', 'while', 'for', 'def']
    call add(rules, lexima#endwise_rule#make_rule('^\s*' . at . '\>.*\%#$', 'end' . at, 'vim', []))
  endfor
  call add(rules, lexima#endwise_rule#make_rule('^\s*export def\>.*\%#$', 'enddef', 'vim', []))
  call add(rules, lexima#endwise_rule#make_rule('^\s*try\>.*\%#$', 'endtry', 'vim', [], ['catch']))
  call add(rules, lexima#endwise_rule#make_rule('^\s*if\>.*\%#$', 'endif', 'vim', [], ['else', 'elseif']))
  for at in ['aug', 'augroup']
    call add(rules, lexima#endwise_rule#make_rule('^\s*' . at . '\s\+.\+\%#$', at . ' END', 'vim', []))
  endfor

  " ruby
  call add(rules, lexima#endwise_rule#make_rule('^\s*\%(module\|class\|unless\|for\|while\|until\|case\)\>\%(.*[^.:@$]\<end\>\)\@!.*\%#$', 'end', 'ruby', []))
  call add(rules, lexima#endwise_rule#make_rule('^\s*\%(if\|unless\)\>\%(.*[^.:@$]\<end\>\)\@!.*\%#$', 'end', 'ruby', [], ['else', 'elsif']))
  call add(rules, lexima#endwise_rule#make_rule('^\s*\%(def\)\>\%(.*[^.:@$]\<end\>\)\@!.*\%#$', 'end', 'ruby', [], ['rescue']))
  call add(rules, lexima#endwise_rule#make_rule('^\s*\%(begin\)\s*\%#$', 'end', 'ruby', [], ['rescue']))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!do\%(\s*|.*|\)\?\s*\%#$', 'end', 'ruby', []))
  call add(rules, lexima#endwise_rule#make_rule('\<.*=.*\%(if\|unless\)\>.*\%#$', 'end', 'ruby', 'rubyConditionalExpression', ['else', 'elsif']))

  " elixir
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!do\s*\%#$', 'end', 'elixir', [], ['rescue']))

  " sh
  call add(rules, lexima#endwise_rule#make_rule('^\s*if\>.*\%#$', 'fi', ['sh', 'zsh'], [], ['else', 'elif']))
  call add(rules, lexima#endwise_rule#make_rule('^\s*case\>.*\%#$', 'esac', ['sh', 'zsh'], []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!do\>.*\%#$', 'done', ['sh', 'zsh'], []))

  " julia
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!\<\%(module\|struct\|function\|for\|while\|do\|let\|macro\)\>\%(.*\<end\>\)\@!.*\%#$', 'end', 'julia', []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!\<\%(if\)\>\%(.*\<end\>\)\@!.*\%#$', 'end', 'julia', [], ['else', 'elseif']))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!\s*\<\%(begin\|quote\)\s*\%#$', 'end', 'julia', []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*#.*\)\@<!\s*\<try\s*\%#$', 'end', 'julia', [], ['catch']))

  " lua
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*--.*\)\@<!\<function\>\%(.*\<end\>\)\@!.*\%#$', 'end', 'lua', []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*--.*\)\@<!\<do\s*\%#$', 'end', 'lua', []))
  call add(rules, lexima#endwise_rule#make_rule('\%(^\s*--.*\)\@<!\<then\s*\%#$', 'end', 'lua', []))

  return rules
endfunction

function! lexima#endwise_rule#make_rule(at, end, filetype, syntax, ...)
  let not_before = empty(a:000) ? [a:end] : [a:end] + a:1
  return {
  \ 'char': '<CR>',
  \ 'input': s:cr_key,
  \ 'input_after': '<CR>' . a:end,
  \ 'at': a:at,
  \ 'except': '\C\v^(\s*)\S.*%#\n%(%(\s*|\1\s.+)\n)*\1(' . not_before->join('|') . ')',
  \ 'filetype': a:filetype,
  \ 'syntax': a:syntax,
  \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
