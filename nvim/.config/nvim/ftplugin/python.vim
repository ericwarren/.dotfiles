syntax on                       "syntax highlighting, see :help syntax
filetype plugin indent on       "file type detection, see :help filetype
set number                      "display line number
set relativenumber              "display relative line numbers
set path+=**                    "improves searching, see :help path
set wildmenu                    "completion menu
set backspace=indent,eol,start  "ensure proper backspace functionality
set incsearch                   "see results while search is being typed, see :help incsearch
set smartindent                 "auto indent on new lines, see :help smartindent
set ic                          "ignore case when searching
set colorcolumn=80              "display color when line reaches pep8 standards
set expandtab                   "expanding tab to spaces
set tabstop=4                   "setting tab to 4 columns
set shiftwidth=4                "setting tab to 4 columns
set softtabstop=4               "setting tab to 4 columns
set showmatch                   "display matching bracket or parenthesis
set hlsearch incsearch          "highlight all pervious search pattern with incsearch

highlight ColorColumn ctermbg=9 "display ugly bright red bar at color column number

" Keybind Ctrl+l to clear search
nnoremap <C-l> :nohl<CR><C-l>:echo "Search Cleared"<CR>

" When python filetype is detected, F5 can be used to execute script 
autocmd FileType python nnoremap <buffer> <F5> :w<cr>:exec '!clear'<cr>:exec '!python3' shellescape(expand('%:p'), 1)<cr>
