return {
  -- Treesitter for syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufReadPost', 'BufNewFile' },
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'lua',
          'vim',
          'vimdoc',
          'rust',
          'typescript',
          'javascript',
          'python',
          'c_sharp',
          'go',
          'markdown',
          'markdown_inline',
          'bash',
          'yaml',
          'json',
          'html',
          'css',
        },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    end
  },

  -- Autocompletion with LSP support
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
    },
    config = function()
      local cmp = require('cmp')

      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' },
        }),
      })
    end
  },

  -- File Explorer
  {
    'nvim-tree/nvim-tree.lua',
    cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('nvim-tree').setup({
        sort_by = 'case_sensitive',
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
      })
    end
  },

  -- Comment Plugin
  {
    'numToStr/Comment.nvim',
    keys = {
      { 'gcc', mode = 'n', desc = 'Comment toggle current line' },
      { 'gc', mode = { 'n', 'o' }, desc = 'Comment toggle linewise' },
      { 'gc', mode = 'x', desc = 'Comment toggle linewise (visual)' },
      { 'gbc', mode = 'n', desc = 'Comment toggle current block' },
      { 'gb', mode = { 'n', 'o' }, desc = 'Comment toggle blockwise' },
      { 'gb', mode = 'x', desc = 'Comment toggle blockwise (visual)' },
    },
    config = function()
      require('Comment').setup()
    end
  },

  -- Autopairs
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = function()
      require('nvim-autopairs').setup({
        check_ts = true,
      })
      -- Integration with nvim-cmp
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end
  },

  -- Color highlighter - shows hex colors inline
  {
    'NvChad/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('colorizer').setup({
        filetypes = {
          '*', -- Enable for all filetypes
          css = { rgb_fn = true }, -- Enable parsing rgb(...) functions in css
          html = { names = false }, -- Disable parsing "names" like Blue or Gray
        },
        user_default_options = {
          RGB = true, -- #RGB hex codes
          RRGGBB = true, -- #RRGGBB hex codes
          names = false, -- "Name" codes like Blue or red
          RRGGBBAA = true, -- #RRGGBBAA hex codes
          rgb_fn = true, -- CSS rgb() and rgba() functions
          hsl_fn = true, -- CSS hsl() and hsla() functions
          css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
          mode = 'background', -- Set the display mode
        },
      })
    end,
  },

  -- Color scheme
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('tokyonight').setup({
        style = 'night',
        transparent = false,
        terminal_colors = true,
      })
      vim.cmd([[colorscheme tokyonight]])
    end,
  },

  -- LSP Installer
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    build = ':MasonUpdate',
  },

  -- LSP Configuration Bridge
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = {
      'williamboman/mason.nvim',
    },
  },

  -- LSP Configurations
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'hrsh7th/cmp-nvim-lsp',
    },
  },

  -- Formatting
  {
    'stevearc/conform.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
  },

  -- Fuzzy Finder
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = function()
      require('telescope').setup({
        defaults = {
          file_ignore_patterns = { 'node_modules', '.git/' },
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
            },
          },
        },
      })
    end,
  },

  -- Buffer tabs
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('bufferline').setup({
        options = {
          mode = 'buffers',
          numbers = 'none',
          close_command = 'bdelete! %d',
          right_mouse_command = 'bdelete! %d',
          left_mouse_command = 'buffer %d',
          middle_mouse_command = nil,
          indicator = {
            style = 'icon',
            icon = '▎',
          },
          buffer_close_icon = '',
          modified_icon = '●',
          close_icon = '',
          left_trunc_marker = '',
          right_trunc_marker = '',
          diagnostics = 'nvim_lsp',
          diagnostics_indicator = function(count, level)
            local icon = level:match('error') and ' ' or ' '
            return ' ' .. icon .. count
          end,
          offsets = {
            {
              filetype = 'NvimTree',
              text = 'File Explorer',
              highlight = 'Directory',
              text_align = 'left',
            },
          },
          show_buffer_icons = true,
          show_buffer_close_icons = true,
          show_close_icon = true,
          show_tab_indicators = true,
          separator_style = 'thin',
          always_show_bufferline = true,
        },
      })
    end,
  },

  -- Git signs
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('gitsigns').setup({
        signs = {
          add = { text = '│' },
          change = { text = '│' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
          interval = 1000,
          follow_files = true,
        },
        attach_to_untracked = true,
        current_line_blame = false,
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length = 40000,
      })
    end,
  },

  -- Terminal
  {
    'akinsho/toggleterm.nvim',
    cmd = 'ToggleTerm',
    config = function()
      require('toggleterm').setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = 'float',
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = 'curved',
          winblend = 0,
          highlights = {
            border = 'Normal',
            background = 'Normal',
          },
        },
      })
    end,
  },
}