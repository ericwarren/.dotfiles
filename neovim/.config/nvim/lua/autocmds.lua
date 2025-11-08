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

-- HTML/CSS/JSON/YAML
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

-- Go
autocmd("FileType", {
  group = lang_group,
  pattern = "go",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = false  -- Go uses tabs
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
