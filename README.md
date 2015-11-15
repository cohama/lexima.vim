lexima.vim
==========
[![Build Status](https://travis-ci.org/cohama/lexima.vim.svg)](https://travis-ci.org/cohama/lexima.vim)

Auto close parentheses and repeat by dot dot dot...

Basically, you can automatically close pairs such as `()`, `{}`, `""`, ...
But in advance, you can also customize the rule to automatically input
any character on any context.

Screen Shots
-----------
![Screen Shot](http://i.gyazo.com/af2d7a59c82f93e49a6fd424dbbf6f88.gif)


DEFAULT RULES
-------------

lexima.vim provides some default rules to input pairs.
(the cursor position is represented by `|`)

### Basic Rules
If `g:lexima_enable_basic_rules` is `1`, the following rules are enabled.
(default value: `1`)

    Before        Input         After
    ------------------------------------
    |             (             (|)
    ------------------------------------
    |             "             "|"
    ------------------------------------
    ""|           "             """|"""
    ------------------------------------
    ''|           '             '''|'''
    ------------------------------------
    \|            [             \[|
    ------------------------------------
    \|            "             \"|
    ------------------------------------
    \|            '             \'|
    ------------------------------------
    I|            'm            I'm|
    ------------------------------------
    (|)           )             ()|
    ------------------------------------
    '|'           '             ''|
    ------------------------------------
    (|)           <BS>          |
    ------------------------------------
    '|'           <BS>          |
    ------------------------------------

and much more... (See `g:lexima#default_rules` at `autoload/lexima.vim`)

### New Line Rules
If `g:lexima_enable_newline_rules` is `1`, the following rules are enabled.
(default value: `1`)

    Before        Input         After
    ------------------------------------
    {|}           <CR>          {
                                    |
                                }
    ------------------------------------
    {|            <CR>          {
                                    |
                                }
    ------------------------------------

Same as `()` and `[]`.

### Endwise Rules
If `g:lexima_enable_endwise_rules` is `1`, the following rules are enabled.
(default value: `1`)

For example, in ruby filetype

    Before        Input         After
    --------------------------------------
    if x == 42|   <CR>          if x == 42
                                    |
                                end
    --------------------------------------
    def foo()|    <CR>          def foo()
                                    |
                                end
    --------------------------------------
    bar.each do|  <CR>          bar.each do
                                    |
                                end
    --------------------------------------

and same as `module`, `class`, `while` and so on.

In vim filetype, `function`, `if`, `while` ... rules are available.
And also you can use in sh (zsh) such as `if`, `case`.


CUSTOMIZATION
-------------
lexima.vim provides highly customizable interface.
You can define your own rule by using `lexima#add_rule()`.


```vim
" Please add below in your vimrc
call lexima#add_rule({'char': '$', 'input_after': '$', 'filetype': 'latex'})
call lexima#add_rule({'char': '$', 'at': '\%#\$', 'leave': 1, 'filetype': 'latex'})
call lexima#add_rule({'char': '<BS>', 'at': '\$\%#\$', 'delete': 1, 'filetype': 'latex'})
```

You will get

    Before  Input   After
    ---------------------
    |       $       $|$
    ---------------------
    $|$     $       $$|
    ---------------------
    $|$     <BS>    |
    ---------------------

These rules are enabled at only `latex` filetype.
For more information, please see `:help lexima-customization`


DOT REPEATABLE
--------------
If you type `foo("bar`, you get
```
foo("bar")
```

and once you type `0.`, you finally get
```
foo("bar")foo("bar")
```
