-- Treesitter for syntax highlighting and parsing
return {
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufReadPost', 'BufNewFile' },
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
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
    },
  },
}
