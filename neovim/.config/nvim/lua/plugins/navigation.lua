-- File and code navigation plugins
return {
  -- File Explorer
  {
    'nvim-tree/nvim-tree.lua',
    cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      sort_by = 'case_sensitive',
      view = {
        width = 30,
      },
      renderer = {
        group_empty = true,
        icons = {
          show = {
            git = true,
            folder = true,
            file = true,
            folder_arrow = true,
          },
        },
      },
      filters = {
        dotfiles = false,
      },
      git = {
        enable = true,
        ignore = false,
      },
    },
  },

  -- Fuzzy Finder
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {
      defaults = {
        file_ignore_patterns = { 'node_modules', '.git/' },
        mappings = {
          i = {
            ['<C-u>'] = false,
            ['<C-d>'] = false,
          },
        },
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
          '--hidden', -- Search hidden files
        },
      },
    },
  },
}
