local opt = vim.opt

-- UI
opt.number         = true       -- line numbers
opt.relativenumber = true       -- relative line numbers
opt.signcolumn     = "yes"      -- always show sign column
opt.cursorline     = true       -- highlight current line
opt.termguicolors  = true
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.wrap           = false
opt.colorcolumn    = "120"      -- guide for long lines

-- Indentation (2 spaces)
opt.tabstop        = 2
opt.shiftwidth     = 2
opt.expandtab      = true
opt.smartindent    = true

-- Search
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = true
opt.incsearch      = true

-- Files
opt.undofile       = true       -- persistent undo
opt.swapfile       = false
opt.backup         = false
opt.updatetime     = 250

-- Splits
opt.splitright     = true
opt.splitbelow     = true

-- Clipboard
opt.clipboard      = "unnamedplus"  -- use system clipboard

-- Completion
opt.completeopt    = "menu,menuone,noselect"

-- Folding (uses TreeSitter)
opt.foldmethod     = "expr"
opt.foldexpr       = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable     = false      -- open all folds by default
