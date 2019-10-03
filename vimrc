let mapleader=" "
syntax on
"basic
set number
set norelativenumber
set wrap
set mouse=a
set encoding=utf-8
set wildmenu
let &t_ut=''
let g:airline_powerline_fonts = 1
"search related
set hlsearch
exec "nohlsearch"
set incsearch
set ignorecase
set smartcase
noremap <LEADER><CR> :nohlsearch<CR>
" cursor
let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"
"don't know
set cursorline
set showcmd
set nocompatible
filetype on
filetype indent on
filetype plugin on
filetype plugin indent on
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set list
set listchars=tab:▸\ ,trail:▫
set scrolloff=5
set tw=0
set indentexpr=
set backspace=indent,eol,start
set foldmethod=indent
set foldlevel=99
set laststatus=2
set autochdir
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif


"basic save and quit
map s <nop>
map S :w<CR>
map Q :q<CR>
map R :source $MYVIMRC<CR>
map ; :

"===
"=== hjkl related
"===
" move cursor
noremap j h
noremap l l
noremap i k
noremap k j
noremap I 5k
noremap K 5j
noremap J 5h
noremap L 5l

noremap <C-l> $
noremap <C-j> 0

noremap h i
noremap H I

" split screen and move between screen
map sl :set splitright<CR>:vsplit<CR>
map sj :set nosplitright<CR>:vsplit<CR>
map si :set nosplitbelow<CR>:split<CR>
map sk :set splitbelow<CR>:split<CR>

map <LEADER>j <C-w>h
map <LEADER>l <C-w>l
map <LEADER>i <C-w>k
map <LEADER>k <C-w>j

map <up> :res +5<CR>
map <down> :res -5<CR>
map <left> :vertical resize -5<CR>
map <right> :vertical resize +5<CR>

map sh <C-w>H
map sv <C-w>K
"tap 
map T :tabe<CR>
map <C-T> :tabe<CR>:edit 
map tj :-tabnext<CR> 
map tl :+tabnext<CR> 



call plug#begin('~/.vim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'connorholyday/vim-snazzy'



" File navigation
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'Xuyuanp/nerdtree-git-plugin'

" Undo Tree
Plug 'mbbill/undotree/'

" Bookmarks
Plug 'kshenoy/vim-signature'

" Error checking
Plug 'w0rp/ale'

" Auto Complete
"Plug 'Valloric/YouCompleteMe'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Other useful utilities
Plug 'junegunn/goyo.vim' " distraction free writing mode
Plug 'scrooloose/nerdcommenter' " in <space>cc to comment a line
"     Taglist
Plug 'majutsushi/tagbar', { 'on': 'TagbarOpenAutoClose' }

call plug#end()

let g:airline#extensions#tabline#enabled = 1
let g:SnazzyTransparent = 1
color snazzy

" ===
" === NERDTree
" ===
map tt :NERDTreeToggle<CR>
" move 
let NERDTreeMapActivateNode = "l"
let NERDTreeMapCWD = "L"
let NERDTreeMapUpdirKeepOpen = "J"
let NERDTreeMapJumpParent = "j"
let NERDTreeMapJumpFirstChild = "<C-I>"
let NERDTreeMapJumpNextSibling = "K"
let NERDTreeMapJumpPrevSibling = "I"
let NERDTreeMapJumpLastChild = "<C-K>"
" open way
let NERDTreeMapOpenSplit = "s"

" ==
" == NERDTree-git
" ==
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ "Unknown"   : "?"
    \ }

" ===
" === Undotree
" ===
let g:undotree_DiffAutoOpen = 0
map ud :UndotreeToggle<CR>

" ===
" === vim-signiture
" ===
let g:SignatureMap = {
        \ 'Leader'             :  "m",
        \ 'PlaceNextMark'      :  "m,",
        \ 'ToggleMarkAtLine'   :  "m.",
        \ 'PurgeMarksAtLine'   :  "dm-",
        \ 'DeleteMark'         :  "dm",
        \ 'PurgeMarks'         :  "dm/",
        \ 'PurgeMarkers'       :  "dm?",
        \ 'GotoNextLineAlpha'  :  "m<LEADER>",
        \ 'GotoPrevLineAlpha'  :  "",
        \ 'GotoNextSpotAlpha'  :  "m<LEADER>",
        \ 'GotoPrevSpotAlpha'  :  "",
        \ 'GotoNextLineByPos'  :  "",
        \ 'GotoPrevLineByPos'  :  "",
        \ 'GotoNextSpotByPos'  :  "mn",
        \ 'GotoPrevSpotByPos'  :  "mp",
        \ 'GotoNextMarker'     :  "",
        \ 'GotoPrevMarker'     :  "",
        \ 'GotoNextMarkerAny'  :  "",
        \ 'GotoPrevMarkerAny'  :  "",
        \ 'ListLocalMarks'     :  "m/",
        \ 'ListLocalMarkers'   :  "m?"
        \ }

" ===
" === Taglist
" ===
map <silent> tag :TagbarOpenAutoClose<CR>

" ===
" === Goyo
" ===
map <LEADER>gy :Goyo<CR>

" ===
" === ale
" ===
"let b:ale_linters = ['pylint']
"let b:ale_fixers = ['autopep8', 'yapf']

