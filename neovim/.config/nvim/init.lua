-- Minimal Neovim 0.12 config for reading source code.
-- Plugins: built-in vim.pack (:h vim.pack). LSP: built-in vim.lsp (configs in lsp/).

-- Set leader key early (before any plugins load)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Yank to/paste from system clipboard
vim.opt.clipboard:append("unnamedplus")

require('settings')
require('keymaps')
require('plugins')
require('autocmds')

-- LSP: server definitions live in lsp/<name>.lua; only enable the ones
-- whose binary is actually installed on this machine.
local servers = {
  rust_analyzer = 'rust-analyzer',
  clangd = 'clangd',
  gopls = 'gopls',
  pyright = 'pyright-langserver',
  ts_ls = 'typescript-language-server',
}
for name, bin in pairs(servers) do
  if vim.fn.executable(bin) == 1 then
    vim.lsp.enable(name)
  end
end

-- Diagnostics presentation (sign icons must go through vim.diagnostic.config
-- now; sign_define is deprecated)
vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = '●' },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = ' ',
      [vim.diagnostic.severity.WARN] = ' ',
      [vim.diagnostic.severity.HINT] = ' ',
      [vim.diagnostic.severity.INFO] = ' ',
    },
  },
  float = { border = 'rounded' },
})

-- WSL clipboard integration (no-op on macOS/Linux)
if vim.fn.has('wsl') == 1 then
  vim.g.clipboard = {
    name = 'WslClipboard',
    copy = {
      ['+'] = 'clip.exe',
      ['*'] = 'clip.exe',
    },
    paste = {
      ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end
