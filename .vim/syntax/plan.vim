" Vim syntax file
" Language:	Text Plan
" Maintainer:	Demian Neidetcher <demian0311@gmail.com>
" Updated:     	" put this in ~/.vim/syntax/plan.vim
" :set syntax=plan

syn match   task		"@.*$" 
syn match   taskInProgress	"/.*$" 
syn match   taskDone 		"x.*$" 
syn match   taskDelegated 	">.*$" 
syn match   taskWaiting         "!.*$"
syn match   information 	"-.*$" 
syn match   header1 		"==.*$" 
syn match   question 		"?.*$" 

" all these colors are lifted from solarized
highlight task 			ctermfg=red guifg=#dc322f
highlight taskInProgress 	ctermfg=Yellow guifg=Yellow
highlight taskDone 		ctermfg=Green guifg=Green
highlight taskDelegated         ctermfg=Cyan guifg=Cyan
highlight taskWaiting           ctermfg=LightYellow guifg=LightYellow
highlight information 		ctermfg=LightGray guifg=LightGray
highlight header1 		ctermfg=Black ctermbg=White guifg=Black guibg=White
highlight question 		ctermfg=Magenta guifg=Magenta

let b:current_syntax = "plan"

" vim: ts=8
