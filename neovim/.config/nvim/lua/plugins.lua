return require('lazy').setup({
  -- GitHub Copilot
  'github/copilot.vim',

  -- Treesitter for better syntax highlighting and parsing
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        -- Install parsers for these languages
        ensure_installed = {
          'c_sharp',
          'rust',
          'typescript',
          'javascript',
          'python',
          'lua',
          'vim',
          'vimdoc',
          'html',
          'css',
          'json',
          'yaml',
          'markdown',
          'bash',
        },
        
        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,
        
        -- Automatically install missing parsers when entering buffer
        auto_install = true,
        
        highlight = {
          enable = true,
          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
        
        indent = {
          enable = true
        },
        
        -- Enable incremental selection
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<C-space>',
            node_incremental = '<C-space>',
            scope_incremental = '<C-s>',
            node_decremental = '<C-backspace>',
          },
        },
      })
    end,
  },

  -- Autocompletion engine
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',     -- LSP source for nvim-cmp
      'hrsh7th/cmp-buffer',       -- Buffer completions
      'hrsh7th/cmp-path',         -- Path completions
      'hrsh7th/cmp-cmdline',      -- Command line completions
      'L3MON4D3/LuaSnip',         -- Snippet engine
      'saadparwaiz1/cmp_luasnip', -- Snippet completions
      'rafamadriz/friendly-snippets', -- Collection of snippets
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      
      -- Load snippets from friendly-snippets
      require('luasnip.loaders.from_vscode').lazy_load()
      
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },    -- LSP completions
          { name = 'luasnip' },     -- Snippet completions
        }, {
          { name = 'buffer' },      -- Buffer completions
          { name = 'path' },        -- Path completions
        }),
        
        -- Formatting for completion menu
        formatting = {
          format = function(entry, vim_item)
            -- Kind icons
            local kind_icons = {
              Text = "",
              Method = "󰆧",
              Function = "󰊕",
              Constructor = "",
              Field = "󰇽",
              Variable = "󰂡",
              Class = "󰠱",
              Interface = "",
              Module = "",
              Property = "󰜢",
              Unit = "",
              Value = "󰎠",
              Enum = "",
              Keyword = "󰌋",
              Snippet = "",
              Color = "󰏘",
              File = "󰈙",
              Reference = "",
              Folder = "󰉋",
              EnumMember = "",
              Constant = "󰏿",
              Struct = "",
              Event = "",
              Operator = "󰆕",
              TypeParameter = "󰅲",
            }
            
            vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            
            return vim_item
          end
        },
      })
      
      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })
      
      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
    end,
  },

  -- Telescope (file finder)
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          -- Default configuration for telescope goes here:
          mappings = {
            i = {
              -- Insert mode mappings
              ["<C-n>"] = "move_selection_next",
              ["<C-p>"] = "move_selection_previous",
            },
            n = {
              -- Normal mode mappings
              ["<C-n>"] = "move_selection_next",
              ["<C-p>"] = "move_selection_previous",
            },
          },
        },
      })
    end,
  },

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
          'omnisharp',        -- C# language server
          'lua_ls',           -- Lua language server
        },
      })
    end
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = { 'mason-lspconfig.nvim', 'nvim-cmp' },
    config = function()
      local lspconfig = require('lspconfig')
      
      -- Get the capabilities from nvim-cmp to support autocompletion
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      -- Basic server setups with completion capabilities
      lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
      })
      
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
      })
      
      lspconfig.pyright.setup({
        capabilities = capabilities,
      })
      
      -- C# setup
      lspconfig.omnisharp.setup({
        capabilities = capabilities,
        cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
        -- Enable import completion
        enable_import_completion = true,
        -- Organize imports on format
        organize_imports_on_format = true,
        -- Enable completion in comments
        enable_ms_build_load_projects_on_demand = false,
      })
      
      -- Lua setup (for editing Neovim config)
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT',
            },
            diagnostics = {
              globals = {'vim'},
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })
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