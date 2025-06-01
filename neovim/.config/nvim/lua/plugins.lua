return require('lazy').setup({
  -- GitHub Copilot - AI-powered code completion
  'github/copilot.vim',

  -- Modern C# Language Server (replaces OmniSharp)
  {
    'seblyng/roslyn.nvim',
    ft = 'cs',
    dependencies = { 'nvim-lspconfig' },
    config = function()
      require('roslyn').setup({
        dotnet_cmd = "dotnet",
        on_attach = function(client, bufnr)
          -- LSP keymaps
          local opts = { buffer = bufnr, silent = true }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<leader>vws', vim.lsp.buf.workspace_symbol, opts)
          vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float, opts)
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
          vim.keymap.set('n', '<leader>vca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<leader>vrr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<leader>vrn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<C-h>', vim.lsp.buf.signature_help, opts)
        end,
        capabilities = require('cmp_nvim_lsp').default_capabilities(),
        settings = {
          -- Enable inlay hints
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
          -- Enable code lens
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
            dotnet_enable_tests_code_lens = true,
          },
          -- Enable completion settings
          ["csharp|completion"] = {
            dotnet_provide_regex_completions = true,
            dotnet_show_completion_items_from_unimported_namespaces = true,
            dotnet_show_name_completion_suggestions = true,
          },
          -- Symbol search settings
          ["csharp|symbol_search"] = {
            dotnet_search_reference_assemblies = true,
          },
          -- Background analysis settings
          ["csharp|background_analysis"] = {
            dotnet_analyzer_diagnostics_scope = "fullSolution",
            dotnet_compiler_diagnostics_scope = "fullSolution",
          },
        },
      })
    end,
  },

  -- Treesitter for better syntax highlighting and parsing
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
      'L3MON4D3/Lu