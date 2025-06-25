-- .NET integration for Neovim with custom ToggleTerm layouts
-- Save as ~/.config/nvim/lua/dotnet.lua

local M = {}

-- Only set up if not already done
if vim.g.dotnet_setup_done then
    return M
end

-- Dependencies
local Terminal = require('toggleterm.terminal').Terminal

-- Store our terminals
M.terminals = {}

-- Find project directory
local function find_project_dir()
    local current_dir = vim.fn.expand('%:p:h')
    local patterns = { '*.csproj', '*.sln', '.git' }

    for _, pattern in ipairs(patterns) do
        local found = vim.fn.findfile(pattern, current_dir .. ';')
        if found ~= '' then
            return vim.fn.fnamemodify(found, ':h')
        end
    end

    return vim.fn.getcwd()
end

-- Initialize .NET development terminals
local function init_terminals()
    local project_dir = find_project_dir()

    -- Terminal 1: General purpose (for ad-hoc commands)
    M.terminals.general = Terminal:new({
        cmd = vim.o.shell,
        dir = project_dir,
        direction = "vertical",
        size = vim.o.columns * 0.4,
        hidden = true,
        count = 1,
        display_name = "General",
        on_open = function(term)
            vim.cmd("startinsert!")
        end,
    })

    -- Terminal 2: Dotnet watch run (persistent)
    M.terminals.watch_run = Terminal:new({
        cmd = vim.o.shell,
        dir = project_dir,
        direction = "horizontal",
        size = 12,
        hidden = true,
        count = 2,
        display_name = "Watch Run",
        close_on_exit = false,
        on_open = function(term)
            -- Don't auto-start the command, let user control it
            vim.cmd("startinsert!")
        end,
    })

    -- Terminal 3: Test runner
    M.terminals.test = Terminal:new({
        cmd = vim.o.shell,
        dir = project_dir,
        direction = "horizontal",
        size = 20,
        hidden = true,
        count = 3,
        display_name = "Tests",
        on_open = function(term)
            vim.cmd("startinsert!")
        end,
    })

    -- Terminal 4: Git operations (floating)
    M.terminals.git = Terminal:new({
        cmd = vim.o.shell,
        dir = project_dir,
        direction = "float",
        hidden = true,
        count = 4,
        display_name = "Git",
        float_opts = {
            border = "double",
            width = 0.9,
            height = 0.9,
        },
        on_open = function(term)
            vim.cmd("startinsert!")
            -- ESC to close floating terminal
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<esc>", "<cmd>close<CR>", {noremap = true, silent = true})
        end,
    })

    -- Terminal 5: Package management
    M.terminals.package = Terminal:new({
        cmd = vim.o.shell,
        dir = project_dir,
        direction = "float",
        hidden = true,
        count = 5,
        display_name = "Packages",
        float_opts = {
            border = "rounded",
            width = 0.8,
            height = 0.6,
        },
    })

    -- Terminal 6: Database/EF operations
    M.terminals.database = Terminal:new({
        cmd = vim.o.shell,
        dir = project_dir,
        direction = "vertical",
        size = vim.o.columns * 0.5,
        hidden = true,
        count = 6,
        display_name = "Database",
    })
end

-- Terminal management functions
M.toggle_general = function()
    M.terminals.general:toggle()
end

M.toggle_watch = function()
    M.terminals.watch_run:toggle()
end

M.toggle_test = function()
    M.terminals.test:toggle()
end

M.toggle_git = function()
    M.terminals.git:toggle()
end

-- Run command in specific terminal
local function run_in_terminal(terminal, cmd)
    local project_dir = find_project_dir()
    terminal:open()
    terminal:send("cd '" .. project_dir .. "'")
    terminal:send(cmd)
end

-- .NET Commands
M.run = function()
    run_in_terminal(M.terminals.general, "dotnet run")
end

M.build = function()
    run_in_terminal(M.terminals.general, "dotnet build")
end

M.test = function()
    run_in_terminal(M.terminals.test, "dotnet test")
end

M.watch_run = function()
    run_in_terminal(M.terminals.watch_run, "dotnet watch run")
    vim.notify("Started dotnet watch run", vim.log.levels.INFO)
end

M.watch_test = function()
    run_in_terminal(M.terminals.test, "dotnet watch test")
    vim.notify("Started dotnet watch test", vim.log.levels.INFO)
end

M.stop_watch = function()
    if M.terminals.watch_run:is_open() then
        M.terminals.watch_run:send("\x03") -- Ctrl+C
        vim.notify("Stopped watch run", vim.log.levels.INFO)
    end
    if M.terminals.test:is_open() then
        M.terminals.test:send("\x03")
        vim.notify("Stopped watch test", vim.log.levels.INFO)
    end
end

M.clean = function()
    run_in_terminal(M.terminals.general, "dotnet clean")
end

M.restore = function()
    run_in_terminal(M.terminals.general, "dotnet restore")
end

-- Package management
M.add_package = function()
    vim.ui.input({prompt = "Package name: "}, function(package_name)
        if package_name then
            run_in_terminal(M.terminals.package, "dotnet add package " .. package_name)
        end
    end)
end

M.remove_package = function()
    vim.ui.input({prompt = "Package name: "}, function(package_name)
        if package_name then
            run_in_terminal(M.terminals.package, "dotnet remove package " .. package_name)
        end
    end)
end

M.list_packages = function()
    run_in_terminal(M.terminals.package, "dotnet list package")
end

-- Entity Framework commands
M.ef_add_migration = function()
    vim.ui.input({prompt = "Migration name: "}, function(migration_name)
        if migration_name then
            run_in_terminal(M.terminals.database, "dotnet ef migrations add " .. migration_name)
        end
    end)
end

M.ef_update_database = function()
    run_in_terminal(M.terminals.database, "dotnet ef database update")
end

M.ef_remove_migration = function()
    run_in_terminal(M.terminals.database, "dotnet ef migrations remove")
end

M.ef_list_migrations = function()
    run_in_terminal(M.terminals.database, "dotnet ef migrations list")
end

-- Layout presets
M.layouts = {
    -- Standard development layout: code + watch
    dev = function()
        vim.cmd("only") -- Start with only current window
        M.terminals.watch_run:open()
    end,

    -- Testing layout: code + test runner
    test = function()
        vim.cmd("only")
        M.terminals.test:open()
    end,

    -- Full layout: code + watch + general terminal
    full = function()
        vim.cmd("only")
        M.terminals.watch_run:open()
        vim.cmd("wincmd k") -- Go back to code
        vim.cmd("vsplit") -- Vertical split
        vim.cmd("wincmd l") -- Go to right split
        M.terminals.general:open()
        vim.cmd("wincmd h") -- Back to code
    end,

    -- Database work: code + database terminal
    database = function()
        vim.cmd("only")
        M.terminals.database:open()
    end,
}

-- Apply a layout
M.apply_layout = function(layout_name)
    if M.layouts[layout_name] then
        M.layouts[layout_name]()
        vim.notify("Applied " .. layout_name .. " layout", vim.log.levels.INFO)
    else
        vim.notify("Unknown layout: " .. layout_name, vim.log.levels.ERROR)
    end
end

-- Setup function
M.setup = function()
    if vim.g.dotnet_setup_done then
        return
    end

    -- Initialize terminals
    init_terminals()

    -- Basic commands
    vim.keymap.set("n", "<leader>dr", M.run, { desc = "Run .NET project" })
    vim.keymap.set("n", "<leader>db", M.build, { desc = "Build .NET project" })
    vim.keymap.set("n", "<leader>dt", M.test, { desc = "Test .NET project" })
    vim.keymap.set("n", "<leader>dc", M.clean, { desc = "Clean .NET project" })
    vim.keymap.set("n", "<leader>dR", M.restore, { desc = "Restore packages" })

    -- Watch commands
    vim.keymap.set("n", "<leader>dw", M.watch_run, { desc = "Start dotnet watch run" })
    vim.keymap.set("n", "<leader>dW", M.watch_test, { desc = "Start dotnet watch test" })
    vim.keymap.set("n", "<leader>ds", M.stop_watch, { desc = "Stop watch" })

    -- Terminal toggles
    vim.keymap.set("n", "<leader>d1", M.toggle_general, { desc = "Toggle general terminal" })
    vim.keymap.set("n", "<leader>d2", M.toggle_watch, { desc = "Toggle watch terminal" })
    vim.keymap.set("n", "<leader>d3", M.toggle_test, { desc = "Toggle test terminal" })
    vim.keymap.set("n", "<leader>d4", M.toggle_git, { desc = "Toggle git terminal" })

    -- Package management
    vim.keymap.set("n", "<leader>dpa", M.add_package, { desc = "Add NuGet package" })
    vim.keymap.set("n", "<leader>dpr", M.remove_package, { desc = "Remove NuGet package" })
    vim.keymap.set("n", "<leader>dpl", M.list_packages, { desc = "List NuGet packages" })

    -- Entity Framework
    vim.keymap.set("n", "<leader>dem", M.ef_add_migration, { desc = "Add EF migration" })
    vim.keymap.set("n", "<leader>deu", M.ef_update_database, { desc = "Update EF database" })
    vim.keymap.set("n", "<leader>der", M.ef_remove_migration, { desc = "Remove last EF migration" })
    vim.keymap.set("n", "<leader>del", M.ef_list_migrations, { desc = "List EF migrations" })

    -- Layouts
    vim.keymap.set("n", "<leader>dld", function() M.apply_layout("dev") end, { desc = "Dev layout (code + watch)" })
    vim.keymap.set("n", "<leader>dlt", function() M.apply_layout("test") end, { desc = "Test layout" })
    vim.keymap.set("n", "<leader>dlf", function() M.apply_layout("full") end, { desc = "Full layout" })
    vim.keymap.set("n", "<leader>dlb", function() M.apply_layout("database") end, { desc = "Database layout" })

    -- Quick access
    vim.keymap.set("n", "<F5>", M.run, { desc = "Quick run" })
    vim.keymap.set("n", "<F6>", M.build, { desc = "Quick build" })
    vim.keymap.set("n", "<F7>", M.test, { desc = "Quick test" })
    vim.keymap.set("n", "<F8>", M.watch_run, { desc = "Quick watch" })

    vim.g.dotnet_setup_done = true
end

-- Auto-setup when loaded
vim.defer_fn(M.setup, 100)

return M
