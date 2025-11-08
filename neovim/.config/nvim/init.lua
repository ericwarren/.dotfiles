-- Set to be able to yank from system clipboard
vim.opt.clipboard:append("unnamedplus")

-- Performance optimizations
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1

-- Set leader key early (before any plugins load)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic settings (load immediately for faster startup)
require('settings')
require('keymaps')

-- Bootstrap lazy.nvim with optimizations
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  print("Installing lazy.nvim...")
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  print("lazy.nvim installed!")
end
vim.opt.rtp:prepend(lazypath)

-- Configure lazy.nvim with performance optimizations
require('lazy').setup('plugins', {
  -- Performance optimizations
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true,
    rtp = {
      -- Disable some rtp plugins
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },

  -- UI improvements
  ui = {
    -- Use a nice border for the lazy window
    border = "rounded",
    -- Show loading progress
    backdrop = 60,
  },

  -- Install settings
  install = {
    -- Install missing plugins on startup
    missing = true,
    -- Try to load one of these colorschemes when starting an installation during startup
    colorscheme = { "tokyonight", "habamax" },
  },

  -- Checker settings for plugin updates
  checker = {
    -- Automatically check for plugin updates
    enabled = true,
    concurrency = nil, -- Use default
    notify = false, -- Don't notify (reduces noise, check with :Lazy)
    frequency = 86400, -- Check once per day
    check_pinned = false, -- Don't check pinned plugins
  },

  -- Change detection for config files
  change_detection = {
    enabled = true,
    notify = false, -- Don't notify on every config change (reduces noise)
  },

  -- Default lazy-loading behavior
  defaults = {
    lazy = false, -- Don't lazy-load by default (explicit is better)
    version = false, -- Don't use versions by default (use latest git)
  },
})

-- Load LSP configuration
require('lsp')

-- Load autocommands
require('autocmds')

-- Set up some global functions for debugging
_G.dump = function(...)
  local objects = vim.tbl_map(vim.inspect, {...})
  print(unpack(objects))
end

_G.reload = function(module)
  package.loaded[module] = nil
  return require(module)
end

-- WSL specific optimizations
if vim.fn.has('wsl') == 1 then
  -- Clipboard integration for WSL
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

-- Final startup message
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Only show if we're not opening a specific file
    if vim.fn.argc() == 0 then
      vim.defer_fn(function()
        vim.notify("Neovim ready!", vim.log.levels.INFO, { title = "Startup" })
      end, 100)
    end
  end,
})