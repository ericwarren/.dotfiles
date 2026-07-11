-- Plugins via the built-in package manager (:h vim.pack).
-- Missing plugins are cloned on startup; update with :lua vim.pack.update()

vim.pack.add({
  'https://github.com/folke/tokyonight.nvim',
  -- main branch: the rewrite for nvim 0.12+ (master is frozen)
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/christoomey/vim-tmux-navigator',
})

-- Colorscheme
require('tokyonight').setup({
  style = 'night',
  transparent = false,
  terminal_colors = true,
})
vim.cmd.colorscheme('tokyonight')

-- Treesitter parsers (async; already-installed parsers are skipped).
-- Highlighting/folds are started per-buffer by the FileType autocmd in
-- autocmds.lua via the built-in vim.treesitter.start().
require('nvim-treesitter').install({
  'bash', 'c', 'c_sharp', 'cpp', 'css', 'go', 'html', 'javascript', 'json',
  'lua', 'markdown', 'markdown_inline', 'python', 'rust', 'toml',
  'typescript', 'tsx', 'vim', 'vimdoc', 'yaml',
})

require('telescope').setup({
  defaults = {
    file_ignore_patterns = { 'node_modules', '%.git/' },
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--hidden',
    },
  },
})

require('gitsigns').setup()
