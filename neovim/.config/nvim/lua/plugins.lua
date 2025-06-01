return require('lazy').setup({
  -- GitHub Copilot - AI-powered code completion
  'github/copilot.vim',

  -- Treesitter - Better syntax highlighting and code understanding
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'c_sharp',      -- C#
          'rust',         -- Rust
          'typescript',   -- TypeScript
          'javascript',   -- JavaScript
          'python',       -- Python
          'lua',          -- Lua (for Neovim config)
          'vim',          -- Vim script
          'vimdoc',       -- Vim help files
          'html',         -- HTML
          'css',          -- CSS
          'json',         -- JSON
          'yaml',         -- YAML
          'toml',         -- TOML (Rust config files)
          'markdown',     -- Markdown
          'bash',         -- Bash scripts
          'dockerfile',   -- Docker files
          'gitignore',    -- .gitignore files
          'sql',          -- SQL
        },
        
        sync_install = false,
        auto_install = true,
        
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        
        indent = {
          enable = true
        },
        
        -- Smart text selection
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

  -- Telescope - Fuzzy finder for files, text, and more
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          mappings = {
            i = {
              ['<C-n>'] = 'move_selection_next',
              ['<C-p>'] = 'move_selection_previous',
              ['<C-j>'] = 'move_selection_next',
              ['<C-k>'] = 'move_selection_previous',
            },
          },
          file_ignore_patterns = {
            'node_modules',
            '.git/',
            'target/',      -- Rust build directory
            'bin/',         -- C# build directory
            'obj/',         -- C# build directory
            '__pycache__/', -- Python cache
            '%.pyc',        -- Python compiled files
          },
        },
      })
    end,
  },

  -- File tree
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = {
      'nvim-tree/nvim-web-devicons', -- File icons
    },
    config = function()
      require('nvim-tree').setup({
        disable_netrw = true,
        hijack_netrw = true,
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
    end,
  },

  -- Autocompletion
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',        -- LSP completions
      'hrsh7th/cmp-buffer',          -- Buffer completions
      'hrsh7th/cmp-path',            -- Path completions
      'hrsh7th/cmp-cmdline',         -- Command line completions
      'L3MON4D3/LuaSnip',            -- Snippet engine
      'saadparwaiz1/cmp_luasnip',    -- Snippet completions
      'rafamadriz/friendly-snippets', -- Collection of snippets
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      
      -- Load snippets
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
          
          -- Tab completion
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
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        }),
        
        -- Nice formatting with icons
        formatting = {
          format = function(entry, vim_item)
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
      
      -- Command line completion
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })
      
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

  -- LSP Support
  {
    'williamboman/mason.nvim',
    config = function()
      require('mason').setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end
  },

  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'mason.nvim' },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = {
          'rust_analyzer',    -- Rust
          'ts_ls',           -- TypeScript/JavaScript
          'pyright',         -- Python
          'omnisharp',       -- C#
          'lua_ls',          -- Lua
          'html',            -- HTML
          'cssls',           -- CSS
          'jsonls',          -- JSON
          'yamlls',          -- YAML
          'bashls',          -- Bash
        },
      })
    end
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = { 'mason-lspconfig.nvim', 'nvim-cmp' },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      -- Rust
      lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
        settings = {
          ['rust-analyzer'] = {
            cargo = {
              allFeatures = true,
            },
            procMacro = {
              enable = true,
            },
          },
        },
      })
      
      -- TypeScript/JavaScript
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
      })
      
      -- Python
      lspconfig.pyright.setup({
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
            },
          },
        },
      })
      
      -- C#
      lspconfig.omnisharp.setup({
        capabilities = capabilities,
        cmd = { 
          vim.fn.stdpath("data") .. "/mason/bin/omnisharp",
          "--languageserver", 
          "--hostPID", 
          tostring(vim.fn.getpid()) 
        },
        enable_import_completion = true,
        organize_imports_on_format = true,
        enable_roslyn_analyzers = true,
        root_dir = function(fname)
          return require('lspconfig').util.root_pattern("*.csproj", "*.sln")(fname)
        end,
      })
      
      -- Lua (for Neovim config editing)
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
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })
      
      -- HTML
      lspconfig.html.setup({
        capabilities = capabilities,
      })
      
      -- CSS
      lspconfig.cssls.setup({
        capabilities = capabilities,
      })
      
      -- JSON
      lspconfig.jsonls.setup({
        capabilities = capabilities,
      })
      
      -- YAML
      lspconfig.yamlls.setup({
        capabilities = capabilities,
      })
      
      -- Bash
      lspconfig.bashls.setup({
        capabilities = capabilities,
      })
    end
  },

  -- Git integration
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        signs = {
          add          = { text = '+' },
          change       = { text = '~' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
        },
      })
    end,
  },

  -- Status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'tokyonight',
          component_separators = { left = '', right = ''},
          section_separators = { left = '', right = ''},
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {'filename'},
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
      })
    end,
  },

  -- Buffer line (tabs)
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('bufferline').setup({
        options = {
          numbers = "ordinal",
          diagnostics = "nvim_lsp",
          show_buffer_close_icons = false,
          show_close_icon = false,
          separator_style = "slant",
        }
      })
    end,
  },

  -- Auto pairs for brackets, quotes, etc.
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = function()
      require('nvim-autopairs').setup({})
    end,
  },

  -- Comment toggling
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end,
  },

  -- Indentation guides
  {
    'lukas-reineke/indent-blankline.nvim',
    main = "ibl",
    config = function()
      require('ibl').setup()
    end,
  },

  -- Color scheme
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('tokyonight').setup({
        style = "night",
        transparent = false,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          functions = {},
          variables = {},
        },
      })
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
})