" Demian L. Neidetcher - the 2nd .vimrc

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-sensible'
Plug 'preservim/nerdtree'
call plug#end()

" Toggle NERDTree with <Leader>n (e.g., \n or Space+n)
" nnoremap <Leader>n :NERDTreeToggle<CR>

" Settings
set autoindent        " always do auto indent
set autoread          " if the file changed under us, update
set autowriteall      " do automatic backups
set backup            " before over-writing a file, make a backup
set backupdir=~/.vim/backup  " put backups and temp files in a ~/.vim directory
set directory=~/.vim/backup  " put backups and temp files in a ~/.vim directory
set runtimepath=~/.vim,$VIMRUNTIME
set expandtab         " never insert tab characters, just use spaces

syntax enable

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
set smarttab          " handles spaces just like tabs
set tabstop=3         " how many spaces equal a tab
set visualbell        " flash the screen instead of beeping

" Text file settings
autocmd BufRead *.txt  set textwidth=79 
autocmd BufRead *.txt  match Error /\%>79v./
autocmd BufRead *.plan iab == == <c-r>=strftime("%Y%m%d")<cr> ==

" navigating through tabs
map H :tabp<cr>         " go to the previous tab  
map L :tabn<cr>         " to to the previous tab
map S :so ~/.vimrc<cr>  " re-source the .vimrc file

" abbreviations
iab dln Demian L. Neidetcher
iab currDate <c-r>=strftime("%Y.%m.%d %H:%M")<cr>

" show a cool status line 
:set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\[HEX=\%02.2B]\ [POS=%04l,%04v]\ [%p%%]\ [LEN=%L]
:set laststatus=2

set background=dark
colorscheme nord
