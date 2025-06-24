require('dotnet')

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

-- LSP keymaps
keymap.set("n", "gd", vim.lsp.buf.definition)
keymap.set("n", "gD", vim.lsp.buf.declaration)
keymap.set("n", "gi", vim.lsp.buf.implementation)
keymap.set("n", "gr", vim.lsp.buf.references)
keymap.set("n", "K", vim.lsp.buf.hover)
keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol)
keymap.set("n", "<leader>vd", vim.diagnostic.open_float)
keymap.set("n", "[d", vim.diagnostic.goto_prev)
keymap.set("n", "]d", vim.diagnostic.goto_next)
keymap.set("n", "<leader>vca", vim.lsp.buf.code_action)
keymap.set("n", "<leader>vrr", vim.lsp.buf.references)
keymap.set("n", "<leader>vrn", vim.lsp.buf.rename)
keymap.set("n", "<C-h>", vim.lsp.buf.signature_help)

-- Telescope keymaps
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")
keymap.set("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>")
keymap.set("n", "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>")
keymap.set("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>")

-- File tree (nvim-tree)
keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>")
keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFile<cr>")

-- Buffer management
keymap.set("n", "<leader>bn", "<cmd>bnext<cr>")
keymap.set("n", "<leader>bp", "<cmd>bprevious<cr>")
keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>")
keymap.set("n", "<leader>ba", "<cmd>%bd|e#<cr>") -- Close all buffers except current

-- Buffer line navigation
keymap.set("n", "<A-1>", "<cmd>BufferLineGoToBuffer 1<cr>")
keymap.set("n", "<A-2>", "<cmd>BufferLineGoToBuffer 2<cr>")
keymap.set("n", "<A-3>", "<cmd>BufferLineGoToBuffer 3<cr>")
keymap.set("n", "<A-4>", "<cmd>BufferLineGoToBuffer 4<cr>")
keymap.set("n", "<A-5>", "<cmd>BufferLineGoToBuffer 5<cr>")

-- Git signs
keymap.set("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>")
keymap.set("n", "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<cr>")
keymap.set("n", "]c", "<cmd>Gitsigns next_hunk<cr>")
keymap.set("n", "[c", "<cmd>Gitsigns prev_hunk<cr>")

-- Comment toggling (handled by Comment.nvim)
-- gcc - toggle current line
-- gc in visual mode - toggle selection
-- gcap - toggle around paragraph

-- Window navigation
keymap.set("n", "<C-h>", "<C-w>h")
keymap.set("n", "<C-j>", "<C-w>j")
keymap.set("n", "<C-k>", "<C-w>k")
keymap.set("n", "<C-l>", "<C-w>l")

-- Window resizing
keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>")
keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>")
keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>")
keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>")

-- Terminal
keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>")
keymap.set("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>")
keymap.set("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical size=40<cr>")

-- Quick save and quit
keymap.set("n", "<leader>w", "<cmd>w<cr>")
keymap.set("n", "<leader>q", "<cmd>q<cr>")
keymap.set("n", "<leader>x", "<cmd>x<cr>")
keymap.set("i", "<C-s>", "<Esc><cmd>w<cr>", { desc = "Save and go to normal" })

-- Clear search highlights
keymap.set("n", "<leader>nh", "<cmd>nohl<cr>")

-- Better indenting in visual mode
keymap.set("v", "<", "<gv")
keymap.set("v", ">", ">gv")

-- Move text up and down in visual mode
keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Language-specific keymaps

-- C# specific
--keymap.set("n", "<leader>dr", "<cmd>!dotnet run<cr>")
--keymap.set("n", "<leader>db", "<cmd>!dotnet build<cr>")
--keymap.set("n", "<leader>dt", "<cmd>!dotnet test<cr>")

-- Python specific
keymap.set("n", "<leader>pr", "<cmd>!python %<cr>")
keymap.set("n", "<leader>pt", "<cmd>!python -m pytest<cr>")

-- Node.js specific
keymap.set("n", "<leader>nr", "<cmd>!npm run<cr>")
keymap.set("n", "<leader>ni", "<cmd>!npm install<cr>")
keymap.set("n", "<leader>nt", "<cmd>!npm test<cr>")
