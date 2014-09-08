let s:suite = themis#suite('rules')

function! s:suite.__new_priority_list__()
  let added_rules = themis#suite('add new rules')

  function! added_rules.before_each()
    let g:lexima_no_default_rules = 1
    call lexima#init()
  endfunction

  function! added_rules.with_implicit_priority_are_sorted_by_at_length()
    call lexima#add_rule({'at': 'hoge\%#', 'char': 'k', 'input': 'K'})
    call lexima#add_rule({'at': 'fuga\%#', 'char': 'kk', 'input': 'KK'})
    call lexima#add_rule({'at': 'hoge\%#hoge', 'char': 'j', 'input': 'J'})
    call lexima#add_rule({'at': '', 'char': 'l', 'input': 'L'})
    call lexima#add_rule({'char': 'h', 'input': 'H'})

    call Expect(lexima#get_rules()).to_be_ordered_as([
    \ {'at': 'hoge\%#hoge', 'char': 'j', 'input': 'J'},
    \ {'at': 'fuga\%#', 'char': 'kk', 'input': 'KK'},
    \ {'at': 'hoge\%#', 'char': 'k', 'input': 'K'},
    \ {'char': 'h', 'input': 'H'},
    \ {'at': '', 'char': 'l', 'input': 'L'}
    \ ])
  endfunction

  function! added_rules.prior_explicit_priority()
    call lexima#add_rule({'char': '1'})
    call lexima#add_rule({'char': '2', 'priority': 1})
    call lexima#add_rule({'char': '3'})

    call Expect(lexima#get_rules()).to_be_ordered_as([
    \ {'char': '2', 'priority': 1},
    \ {'char': '3'},
    \ {'char': '1'},
    \ ])
  endfunction

  function! added_rules.prior_syntax()
    call lexima#add_rule({'char': '1'})
    call lexima#add_rule({'char': '2', 'syntax': 'String'})
    call lexima#add_rule({'char': '3', 'syntax': ['String', 'Number']})
    call lexima#add_rule({'char': '4', 'syntax': 'Number'})
    call lexima#add_rule({'char': '5'})

    call Expect(lexima#get_rules()).to_be_ordered_as([
    \ {'char': '4', 'syntax': 'Number'},
    \ {'char': '3', 'syntax': ['String', 'Number']},
    \ {'char': '2', 'syntax': 'String'},
    \ {'char': '5'},
    \ {'char': '1'}
    \ ])
  endfunction

  function! added_rules.prior_filetype()
    call lexima#add_rule({'char': '1'})
    call lexima#add_rule({'char': '2', 'filetype': 'vim'})
    call lexima#add_rule({'char': '3', 'filetype': ['vim', 'ruby']})
    call lexima#add_rule({'char': '4', 'filetype': 'ruby'})
    call lexima#add_rule({'char': '5'})

    call Expect(lexima#get_rules()).to_be_ordered_as([
    \ {'char': '4', 'filetype': 'ruby'},
    \ {'char': '3', 'filetype': ['vim', 'ruby']},
    \ {'char': '2', 'filetype': 'vim'},
    \ {'char': '5'},
    \ {'char': '1'}
    \ ])
  endfunction

  function! added_rules.prior_filetype_syntax_priority_atlength()
    call lexima#add_rule({'char': '1'})
    call lexima#add_rule({'char': '2', 'priority': 1000})
    call lexima#add_rule({'char': '3', 'filetype': 'vim', 'syntax': 'Number'})
    call lexima#add_rule({'char': '4', 'filetype': 'ocaml', 'syntax': 'String', 'priority': 1})
    call lexima#add_rule({'char': '5', 'syntax': 'String'})
    call lexima#add_rule({'char': '6', 'filetype': 'ruby'})
    call lexima#add_rule({'char': '7', 'filetype': 'python', 'priority': 120})
    call lexima#add_rule({'char': '8', 'priority': 10})
    call lexima#add_rule({'char': '9'})

    call Expect(lexima#get_rules()).to_be_ordered_as([
    \ {'char': '4', 'filetype': 'ocaml', 'syntax': 'String', 'priority': 1},
    \ {'char': '3', 'filetype': 'vim', 'syntax': 'Number'},
    \ {'char': '7', 'filetype': 'python', 'priority': 120},
    \ {'char': '6', 'filetype': 'ruby'},
    \ {'char': '5', 'syntax': 'String'},
    \ {'char': '2', 'priority': 1000},
    \ {'char': '8', 'priority': 10},
    \ {'char': '9'},
    \ {'char': '1'}
    \ ])
  endfunction

endfunction
