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

-- Disable some built-in plugins we don't need
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_sql_completion = 1
vim.g.loaded_syntax_completion = 1
vim.g.loaded_xmlformat = 1

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
require('lazy').setup(require('plugins'), {
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
    notify = true, -- Get notified when updates are available
    frequency = 3600, -- Check every hour
    check_pinned = false, -- Don't check pinned plugins
  },

  -- Change detection for config files
  change_detection = {
    enabled = true,
    notify = true, -- Get notified when config changes
  },
})

-- Auto commands for better experience
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- General auto commands
local general_group = augroup("General", { clear = true })

-- Highlight on yank
autocmd("TextYankPost", {
  group = general_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
  end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  group = general_group,
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Auto-resize splits when Neovim window is resized
autocmd("VimResized", {
  group = general_group,
  pattern = "*",
  command = "wincmd =",
})

-- Remember last cursor position
autocmd("BufReadPost", {
  group = general_group,
  pattern = "*",
  callback = function()
    local last_pos = vim.fn.line("'\"")
    if last_pos > 0 and last_pos <= vim.fn.line("$") then
      vim.api.nvim_win_set_cursor(0, {last_pos, 0})
    end
  end,
})

-- Language-specific auto commands
local lang_group = augroup("LanguageSpecific", { clear = true })

-- Python
autocmd("FileType", {
  group = lang_group,
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

-- C#
autocmd("FileType", {
  group = lang_group,
  pattern = "cs",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

-- JavaScript/TypeScript
autocmd("FileType", {
  group = lang_group,
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- Rust
autocmd("FileType", {
  group = lang_group,
  pattern = "rust",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

-- HTML/CSS
autocmd("FileType", {
  group = lang_group,
  pattern = { "html", "css", "scss", "json", "yaml" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- Terminal settings
local term_group = augroup("Terminal", { clear = true })

autocmd("TermOpen", {
  group = term_group,
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.scrolloff = 0
    vim.cmd("startinsert")
  end,
})

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
        vim.notify("Neovim ready! 🚀", vim.log.levels.INFO, { title = "Startup" })
      end, 100)
    end
  end,
})