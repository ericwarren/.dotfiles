-- LSP Configuration

-- Diagnostic settings (sign column only, no virtual text)
vim.diagnostic.config({
  virtual_text = false,  -- Disable inline error messages
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

-- Diagnostic signs
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- LSP keybindings on attach
local on_attach = function(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- Navigation
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)

  -- Hover and help
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, opts)

  -- Code actions and refactoring
  vim.keymap.set('n', '<leader>vca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<leader>vrn', vim.lsp.buf.rename, opts)

  -- Diagnostics
  vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)

  -- Workspace
  vim.keymap.set('n', '<leader>vws', vim.lsp.buf.workspace_symbol, opts)

  -- Formatting (handled by conform.nvim, but keep manual trigger)
  vim.keymap.set('n', '<leader>f', function()
    require("conform").format({ async = true, lsp_fallback = true })
  end, opts)
end

-- Capabilities for nvim-cmp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Mason setup
require("mason").setup({
  ui = {
    border = "rounded",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

-- Language servers to auto-install
local servers = {
  "omnisharp",      -- C#/.NET
  "pyright",        -- Python
  "ts_ls",          -- TypeScript/JavaScript
  "html",           -- HTML
  "cssls",          -- CSS
  "gopls",          -- Go
}

require("mason-lspconfig").setup({
  ensure_installed = servers,
  automatic_installation = true,
})

-- Configure LSP servers using new vim.lsp.config API (Neovim 0.11+)

-- C#/.NET (OmniSharp)
vim.lsp.config.omnisharp = {
  cmd = { "dotnet", vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/OmniSharp.dll" },
  filetypes = { "cs" },
  root_markers = { "*.sln", "*.csproj", "omnisharp.json", "function.json" },
  capabilities = capabilities,
  settings = {
    enable_roslyn_analyzers = true,
    organize_imports_on_format = true,
    enable_import_completion = true,
  }
}

-- Python (Pyright)
vim.lsp.config.pyright = {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json" },
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      }
    }
  }
}

-- TypeScript/JavaScript
vim.lsp.config.ts_ls = {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  capabilities = capabilities,
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }
    }
  }
}

-- HTML
vim.lsp.config.html = {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html" },
  root_markers = { "package.json", ".git" },
  capabilities = capabilities,
}

-- CSS
vim.lsp.config.cssls = {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  root_markers = { "package.json", ".git" },
  capabilities = capabilities,
}

-- Go
vim.lsp.config.gopls = {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  capabilities = capabilities,
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
      gofumpt = true,
    },
  },
}

-- Enable LSP servers for specified filetypes
vim.lsp.enable({ "omnisharp", "pyright", "ts_ls", "html", "cssls", "gopls" })

-- Set up on_attach autocmd for all LSP servers
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    on_attach(client, args.buf)
  end,
})

-- Format on save with conform.nvim
require("conform").setup({
  formatters_by_ft = {
    python = { "isort", "black" },
    javascript = { { "prettierd", "prettier" } },
    typescript = { { "prettierd", "prettier" } },
    javascriptreact = { { "prettierd", "prettier" } },
    typescriptreact = { { "prettierd", "prettier" } },
    css = { { "prettierd", "prettier" } },
    html = { { "prettierd", "prettier" } },
    json = { { "prettierd", "prettier" } },
    yaml = { { "prettierd", "prettier" } },
    markdown = { { "prettierd", "prettier" } },
    go = { "gofmt", "goimports" },
    cs = { "csharpier" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
})
