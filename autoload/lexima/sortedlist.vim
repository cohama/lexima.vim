let s:save_cpo = &cpo
set cpo&vim

let s:L = lexima#vital().L

let s:sortedlist = {
\ "v": []
\ }

function! lexima#sortedlist#new(init_list, PriorityOrderPred)
  let sortedlist =  deepcopy(s:sortedlist)
  let sortedlist.priority_order = a:PriorityOrderPred
  for x in a:init_list
    call sortedlist.add(x)
  endfor
  return sortedlist
endfunction

function! s:sortedlist.add(x)
  let x = a:x
  if empty(self.v)
    call add(self.v, x)
    return
  endif
  let inserting_index = -1
  for i in range(0, len(self.v)-1)
    let order = self.priority_order(self.v[i], x)
    if order ==# -1 || order ==# 0
      let inserting_index = i
      break
    endif
  endfor
  if inserting_index ==# -1
    let inserting_index = len(self.v)
  endif
  call insert(self.v, x, inserting_index)
endfunction

function! s:sortedlist.as_list()
  return deepcopy(self.v)
endfunction

function! s:sortedlist.clear()
  let self.v = []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
