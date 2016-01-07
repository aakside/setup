filetype plugin indent on

set nocompatible
set modelines=0

let mapleader = ","

set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab

set encoding=utf-8
set scrolloff=3
set autoindent
set showmode
set showcmd
set hidden
set wildmenu
set wildmode=list:longest
set visualbell
set ttyfast
set ruler
set backspace=indent,eol,start
set laststatus=2
set formatoptions=qrn1

set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
nnoremap <tab> %
vnoremap <tab> %
set laststatus=2

set statusline=%F%m%r%h%w
set statusline+=:(%l,%c)

set guioptions-=L
set guioptions-=r
set guioptions-=t

set number
set nowrap

if has("terminfo")
  let &t_Co=8
  let &t_Sf="\e[3%p1%dm"
  let &t_Sb="\e[4%p1%dm"
else
  let &t_Co=8
  let &t_Sf="\e[3%dm"
  let &t_Sb="\e[4%dm"
endif

nnoremap <leader>ft Vatzf
nnoremap <leader>S ?{<CR>jV/^\s*\}?$<CR>k:sort<CR>:noh<CR>
nnoremap <leader>w <C-w>v<C-w>l

nnoremap <leader>a :Ack
map <F8> :!/usr/bin/ctags -R --c++-kinds=+p --fields=+iaS --extra=+q.<CR>

nmap <Leader>nt :tabnew<CR>
map <leader><tab> :tabn <CR>
map <leader>p<tab> :tabp <CR>

set t_Co=256
colorscheme mustang
syntax enable

let g:jsx_ext_required = 0

call pathogen#infect()
