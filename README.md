lexima.vim
==========
[![Build Status](https://travis-ci.org/cohama/lexima.vim.svg)](https://travis-ci.org/cohama/lexima.vim)

Auto close parentheses and repeat by dot dot dot...

Basically, you can automatically close pairs such as (), {}, "", ...
But in advance, you can also customize the rule to automatically input
any character on any context.

Screen Shots
-----------
![Screen Shot](http://i.gyazo.com/af2d7a59c82f93e49a6fd424dbbf6f88.gif)


DEFAULT RULES
-------------

lexima.vim provides some default rules to input pairs.
(the cursor position is represented by |)

Before | Input | After
-------|-------|--------
`|`      | `(`     | `(|)`
`|`      | `"`     | `"|"`
`""|`    | `"`     | `"""|"""`
`''|`    | `'`     | `'''|'''`
`\|`     | `[`     | `\[`
`\|`     | `"`     | `\"`
`\|`     | `'`     | `\'`
`I|`     | `'m`    | `I'm`
`(|)`    | `)`     | `()|`
`'|'`    | `'`     | `''|`
`(|)`    | `<BS>`  | `|`
`'|'`    | `<BS>`  | `|`


DOT REPEATABLE
--------------
If you type `foo("bar`, you get
```
foo("bar")
```

and you type `0.`, you finally get
``` 
foo("bar")foo("bar")
```
