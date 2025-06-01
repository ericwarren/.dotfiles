-- Check Neovim version
if vim.fn.has('nvim-0.9') == 0 then
  vim.api.nvim_echo({
    { "Neovim 0.9+ is required for this configuration.\n", "ErrorMsg" },
    { "Please update Neovim or use a simpler configuration.\n", "WarningMsg" }
  }, true, {})
  return
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
require('settings')
require('keymaps')

-- Load plugins with lazy.nvim
-- Using a protected call in case of errors
local status_ok, lazy = pcall(require, "lazy")
if not status_ok then
  vim.api.nvim_echo({
    { "Failed to load lazy.nvim\n", "ErrorMsg" },
    { "Try deleting ~/.local/share/nvim and restarting Neovim\n", "WarningMsg" }
  }, true, {})
  return
end

lazy.setup('plugins', {
  performance = {
    rtp = {
      disabled_plugins = {
        "netrwPlugin",
        "tohtml",
        "tutor",
      },
    },
  },
})