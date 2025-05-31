return require('lazy').setup({
  -- GitHub Copilot
  'github/copilot.vim',

  -- LSP Support
  {
    'williamboman/mason.nvim',
    config = function()
      require('mason').setup()
    end
  },

  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'mason.nvim' },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = {
          'rust_analyzer',
          'ts_ls',
          'pyright',
        },
      })
    end
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = { 'mason-lspconfig.nvim' },
    config = function()
      -- Simple LSP setup without handlers for now
      local lspconfig = require('lspconfig')
      
      -- Basic server setups
      lspconfig.rust_analyzer.setup({})
      lspconfig.ts_ls.setup({})
      lspconfig.pyright.setup({})
    end
  },

  -- Color scheme
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
})