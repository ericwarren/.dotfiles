-- LSP Configuration

-- Diagnostic settings (inline error messages enabled)
vim.diagnostic.config({
  virtual_text = {
    spacing = 4,
    prefix = '●',
  },
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
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, noremap = true, silent = true })
  end

  -- Navigation
  map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
  map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
  map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
  map('n', 'gr', vim.lsp.buf.references, 'Show references')

  -- Hover and help
  map('n', 'K', vim.lsp.buf.hover, 'Hover documentation')
  map('i', '<C-k>', vim.lsp.buf.signature_help, 'Signature help')

  -- Code actions and refactoring
  map('n', '<leader>vca', vim.lsp.buf.code_action, 'Code action')
  map('n', '<leader>vrn', vim.lsp.buf.rename, 'Rename symbol')

  -- Diagnostics
  map('n', '<leader>vd', vim.diagnostic.open_float, 'Show diagnostic')
  map('n', '[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
  map('n', ']d', vim.diagnostic.goto_next, 'Next diagnostic')

  -- Workspace
  map('n', '<leader>vws', vim.lsp.buf.workspace_symbol, 'Workspace symbols')

  -- Formatting (handled by conform.nvim, but keep manual trigger)
  map('n', '<leader>f', function()
    require("conform").format({ async = true, lsp_fallback = true })
  end, 'Format buffer')
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
  "clangd",        -- C/C++
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

-- C/C++
vim.lsp.config.clangd = {
  cmd = { "clangd", "--background-index", "--clang-tidy" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = { "compile_commands.json", "compile_flags.txt", ".git" },
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
vim.lsp.enable({ "clangd", "omnisharp", "pyright", "ts_ls", "html", "cssls", "gopls" })

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
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    css = { "prettierd", "prettier", stop_after_first = true },
    html = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    yaml = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    c = { "clang_format" },
    cpp = { "clang_format" },
    go = { "gofmt", "goimports" },
    cs = { "csharpier" },
    lua = { "stylua" },
  },
  -- Set default options for all format calls
  default_format_opts = {
    lsp_fallback = true,
  },
  -- Format on save configuration
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
  -- Don't notify on every error to reduce noise
  notify_on_error = true,
  notify_no_formatters = false,
})
