local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>pv", vim.cmd.Ex)
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

-- LSP: gd has no built-in LSP mapping; the rest are 0.11+ defaults
-- (grr references, gri implementation, grn rename, gra code action,
--  grt type definition, gO document symbols, K hover, [d ]d diagnostics)
keymap.set("n", "gd", vim.lsp.buf.definition)
keymap.set("n", "gD", vim.lsp.buf.declaration)

-- Telescope keymaps
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")
keymap.set("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>")
keymap.set("n", "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>")
keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>")

-- Buffer management
keymap.set("n", "<leader>bn", "<cmd>bnext<cr>")
keymap.set("n", "<leader>bp", "<cmd>bprevious<cr>")
keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>")

-- Git signs
keymap.set("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>")
keymap.set("n", "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<cr>")
keymap.set("n", "]c", "<cmd>Gitsigns next_hunk<cr>")
keymap.set("n", "[c", "<cmd>Gitsigns prev_hunk<cr>")

-- Window resizing
keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>")
keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>")
keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>")
keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>")

-- Quick save and quit
keymap.set("n", "<leader>w", "<cmd>w<cr>")
keymap.set("n", "<leader>q", "<cmd>q<cr>")

-- Clear search highlights
keymap.set("n", "<leader>nh", "<cmd>nohl<cr>")
