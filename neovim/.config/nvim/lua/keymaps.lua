local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>pv", vim.cmd.Ex)
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")
keymap.set("n", "J", "mzJ`z")
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

-- LSP keymaps (set these in your LSP config)
keymap.set("n", "gd", vim.lsp.buf.definition)
keymap.set("n", "K", vim.lsp.buf.hover)
keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol)
keymap.set("n", "<leader>vd", vim.diagnostic.open_float)
keymap.set("n", "[d", vim.diagnostic.goto_next)
keymap.set("n", "]d", vim.diagnostic.goto_prev)
keymap.set("n", "<leader>vca", vim.lsp.buf.code_action)
keymap.set("n", "<leader>vrr", vim.lsp.buf.references)
keymap.set("n", "<leader>vrn", vim.lsp.buf.rename)

-- Telescope keymaps
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")