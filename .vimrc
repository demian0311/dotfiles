" Demian L. Neidetcher - the 2nd .vimrc
      
" Settings
set autoindent        " always do auto indent
set autoread          " if the file changed under us, update
set autowriteall      " do automatic backups
set backup            " before over-writing a file, make a backup
set backupdir=~/.vim/backup  " put backups and temp files in a ~/.vim directory
set directory=~/.vim  " 
set expandtab         " never insert tab characters, just use spaces

"folding
set foldmethod=indent " automatically indent on indentation
set foldnestmax=2     " don't net folds too much
highlight Folded     guibg=black guifg=darkgrey
highlight FoldColumn guibg=black guifg=darkgrey

set hlsearch          " after a search, hilight the matches
set ignorecase        " ignore case for searches 
set incsearch         " while doing a search, incrementally show matches
set infercase         " for code completion, don't worry about case
set matchpairs+=<:>   " match pairs of angle brackets also for XML & HTML
set nocompatible      " don't try to be like the old vi
set number            " show line numbers
set cursorline        " show a horizontal line at the cursor
set scrolloff=5       " keep the cursor at least 5 lines inside the screen
set shiftround        " when >< shifting, round off to the nearest shiftwidth
set shiftwidth=3      " how far to do indents
set showmatch         " jump to the matching pair briefly
set smartcase         " if you type in uppercase chars in a search, ignore ignorecase
set smartindent       " indent like for Java/ C programs
set smarttab          " handles spaces just like tabs
set tabstop=3         " how many spaces equal a tab
set visualbell        " flash the screen instead of beeping

"highlight Normal ctermbg=black ctermfg=white
"highlight Normal guibg=black guifg=white

" Java settings
"autocmd BufRead *.java match Error /\%>80v./
autocmd BufRead *.java iab println System.out.println("");
autocmd BufRead *.java iab log log.debug("" + );<esc>hhi 

" Text file settings
"autocmd BufRead *.txt  set formatoptions=tqan
autocmd BufRead *.txt  set textwidth=79 
autocmd BufRead *.txt  match Error /\%>79v./
autocmd BufRead *.plan iab == == <c-r>=strftime("%Y%m%d")<cr> ==

" code wrangling
" these scripts have to be on your path
map M :!multiply.py<cr> " code multiplication
map L :!lineUp.py<cr>   " line up visually selected statements
map S :!a2s.py<cr>      " change the name to 'schema'
map A :!s2a.py<cr>      " change the name to 'attribute'

" navigating through tabs
map H :tabp<cr>         " go to the previous tab  
map L :tabn<cr>         " to to the previous tab
"map J :
"map K :

map S :so ~/.vimrc<cr>  " re-source the .vimrc file

" abbreviations
iab dln Demian L. Neidetcher
iab currDate <c-r>=strftime("%Y.%m.%d %H:%M")<cr>
iab teh the
iab <html> <html><cr><head><cr></head><cr><body><cr></body><cr></html><esc>kko

au BufRead,BufNewFile *.plan set filetype=plan 
au! Syntax plan source ~/.vim/syntax/plan.vim

"au BufRead,BufNewFile *.t2t set filetype=txt2tags 
"au! Syntax txt2tags source ~/.vim/syntax/txt2tags.vim
au BufRead,BufNewFile *.md set filetype=markdown 

au BufRead,BufNewFile *.scala set filetype=scala 
au BufRead,BufNewFile *.scala set shiftwidth=2
au! Syntax scala source ~/.vim/syntax/scala.vim

" for gradle builds
au BufRead,BufNewFile *.gradle set filetype=groovy 
au BufRead,BufNewFile *.sbt set filetype=scala 

" show a cool status line 
:set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\[HEX=\%02.2B]\ [POS=%04l,%04v]\ [%p%%]\ [LEN=%L]
:set laststatus=2

" remove the gui menus
:set guioptions-=m
:set guioptions-=T
:set bg=dark
:set syntax=on

" some nerd tree settings
map nt :NERDTreeToggle<CR>
map ntb :Bookmark

syntax on
colorscheme koehler
