-- Auto commands
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local general_group = augroup("General", { clear = true })

-- Highlight on yank
autocmd("TextYankPost", {
  group = general_group,
  pattern = "*",
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 200 })
  end,
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
      vim.api.nvim_win_set_cursor(0, { last_pos, 0 })
    end
  end,
})

-- Treesitter highlighting + folds for any buffer with an installed parser
-- (nvim-treesitter main branch no longer does this itself)
autocmd("FileType", {
  group = augroup("Treesitter", { clear = true }),
  callback = function(ev)
    if pcall(vim.treesitter.start, ev.buf) then
      vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo[0][0].foldmethod = "expr"
    end
  end,
})

-- Terminal settings
autocmd("TermOpen", {
  group = augroup("Terminal", { clear = true }),
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.scrolloff = 0
    vim.cmd("startinsert")
  end,
})
