-- ~/.config/nvim/lua/dotnet.lua
-- Enhanced .NET integration for Neovim with tmux + popup support
-- Watch commands go to dedicated tmux panes, others use popups
-- CORRECTED FOR 1-BASED PANE INDEXING

local M = {}

-- Only set up if not already done
if vim.g.dotnet_setup_done then
    return M
end

-- Check if we're in a tmux session
local function in_tmux()
    return vim.env.TMUX ~= nil
end

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

-- Execute command in tmux pane (for watch commands)
local function run_in_tmux_pane(pane_name, cmd)
    if not in_tmux() then
        vim.notify("Not in tmux session", vim.log.levels.WARN)
        return false
    end

    local project_dir = find_project_dir()

    -- Get current tmux session name
    local session_name = vim.fn.system("tmux display-message -p '#S'"):gsub("\n", "")

    -- Send command to the specific pane by name
    -- ACTUAL LAYOUT FROM dotnet-tmux:
    -- Pane 1: Neovim (left)
    -- Pane 2: Lower-right 
    -- Pane 3: Upper-right
    if pane_name == "dotnet-watch" then
        vim.fn.system(string.format("tmux send-keys -t '%s:dev.3' 'cd %s && %s' Enter", session_name, project_dir, cmd))
    elseif pane_name == "claude-code" then
        vim.fn.system(string.format("tmux send-keys -t '%s:dev.2' 'cd %s && %s' Enter", session_name, project_dir, cmd))
    else
        -- Unknown pane name, return false
        return false
    end

    return true
end

-- Execute command in popup terminal (for build, run, test, etc.)
local function run_in_popup(cmd, title)
    local project_dir = find_project_dir()
    title = title or "Command Output"

    -- Create a popup terminal
    local popup_cmd = string.format(
        'cd %s && %s; echo ""; echo "Press any key to close..."; read -n 1',
        project_dir,
        cmd
    )

    -- Use a floating terminal for the popup
    if in_tmux() then
        -- In tmux, create a new popup window
        local session_name = vim.fn.system("tmux display-message -p '#S'"):gsub("\n", "")
        local tmux_cmd = string.format(
            "tmux display-popup -E -t '%s' 'bash -c \"%s\"'",
            session_name,
            popup_cmd:gsub('"', '\\"')
        )
        vim.fn.system(tmux_cmd)
    else
        -- Fallback to ToggleTerm floating
        local Terminal = require('toggleterm.terminal').Terminal
        local popup_term = Terminal:new({
            cmd = popup_cmd,
            direction = "float",
            float_opts = {
                border = "double",
                width = 0.8,
                height = 0.8,
            },
            close_on_exit = false,
            on_open = function(term)
                vim.cmd("startinsert!")
                -- ESC to close
                vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<esc>", "<cmd>close<CR>", {noremap = true, silent = true})
            end,
        })
        popup_term:open()
    end
end

-- Show command output in Neovim split (alternative popup method)
local function run_with_output(cmd, title)
    local project_dir = find_project_dir()
    title = title or "Command Output"

    -- Create a new buffer for output
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, title)

    -- Open in a split
    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_height(0, 15)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Add close mapping
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', '<cmd>close<CR>', {noremap = true, silent = true})

    -- Run command and capture output
    local full_cmd = string.format('cd %s && %s 2>&1', project_dir, cmd)

    vim.fn.jobstart(full_cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
            if data then
                vim.schedule(function()
                    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
                    vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
                    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
                    -- Auto-scroll to bottom
                    local line_count = vim.api.nvim_buf_line_count(buf)
                    vim.api.nvim_win_set_cursor(0, {line_count, 0})
                end)
            end
        end,
        on_stderr = function(_, data)
            if data then
                vim.schedule(function()
                    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
                    vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
                    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
                end)
            end
        end,
        on_exit = function(_, code)
            vim.schedule(function()
                vim.api.nvim_buf_set_option(buf, 'modifiable', true)
                local status = code == 0 and "✅ SUCCESS" or "❌ FAILED"
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
                    "",
                    string.format("Command finished with exit code: %d %s", code, status),
                    "",
                    "Press 'q' or <Esc> to close"
                })
                vim.api.nvim_buf_set_option(buf, 'modifiable', false)
            end)
        end,
    })
end

-- .NET Commands
M.run = function()
    run_in_popup("dotnet run", "dotnet run")
end

M.build = function()
    run_in_popup("dotnet build", "dotnet build")
end

M.test = function()
    run_in_popup("dotnet test", "dotnet test")
end

M.clean = function()
    run_in_popup("dotnet clean", "dotnet clean")
end

M.restore = function()
    run_in_popup("dotnet restore", "dotnet restore")
end

-- Watch commands - these go to tmux panes
M.watch_run = function()
    if in_tmux() then
        -- Send to the dotnet-watch pane (pane 3 in dev window - upper right)
        local success = run_in_tmux_pane("dotnet-watch", "dotnet watch run")
        if success then
            vim.notify("Started dotnet watch run in terminal pane", vim.log.levels.INFO)
        else
            -- Fallback: use popup
            run_in_popup("dotnet watch run", "dotnet watch run")
            vim.notify("Started dotnet watch run in popup", vim.log.levels.INFO)
        end
    else
        -- Fallback for non-tmux environments
        run_with_output("dotnet watch run", "Watch Run")
    end
end

M.watch_test = function()
    if in_tmux() then
        -- Try test-watch pane first (from Tests tab), then dotnet-watch pane
        local success = run_in_tmux_pane("test-watch", "dotnet watch test")
        if not success then
            success = run_in_tmux_pane("dotnet-watch", "dotnet watch test")
        end

        if success then
            vim.notify("Started dotnet watch test", vim.log.levels.INFO)
        else
            -- Fallback: use popup
            run_in_popup("dotnet watch test", "dotnet watch test")
            vim.notify("Started dotnet watch test in popup", vim.log.levels.INFO)
        end
    else
        run_with_output("dotnet watch test", "Watch Test")
    end
end

M.stop_watch = function()
    if in_tmux() then
        -- Send Ctrl+C to dotnet-watch pane (pane 3)
        local session_name = vim.fn.system("tmux display-message -p '#S'"):gsub("\n", "")
        vim.fn.system(string.format("tmux send-keys -t '%s:dev.3' C-c", session_name))
        vim.notify("Stopped watch in terminal pane", vim.log.levels.INFO)
    else
        vim.notify("Stop watch only works in tmux", vim.log.levels.WARN)
    end
end

-- Package management (popups)
M.add_package = function()
    vim.ui.input({prompt = "Package name: "}, function(package_name)
        if package_name then
            run_in_popup("dotnet add package " .. package_name, "Add Package")
        end
    end)
end

M.remove_package = function()
    vim.ui.input({prompt = "Package name: "}, function(package_name)
        if package_name then
            run_in_popup("dotnet remove package " .. package_name, "Remove Package")
        end
    end)
end

M.list_packages = function()
    run_in_popup("dotnet list package", "Package List")
end

-- Entity Framework commands (popups)
M.ef_add_migration = function()
    vim.ui.input({prompt = "Migration name: "}, function(migration_name)
        if migration_name then
            run_in_popup("dotnet ef migrations add " .. migration_name, "Add Migration")
        end
    end)
end

M.ef_update_database = function()
    run_in_popup("dotnet ef database update", "Update Database")
end

M.ef_remove_migration = function()
    run_in_popup("dotnet ef migrations remove", "Remove Migration")
end

M.ef_list_migrations = function()
    run_in_popup("dotnet ef migrations list", "List Migrations")
end

-- tmux-specific commands (CORRECTED FOR 1-BASED INDEXING)
M.focus_watch_pane = function()
    if in_tmux() then
        -- Navigate to terminal pane (pane 3 - upper right)
        local session_name = vim.fn.system("tmux display-message -p '#S'"):gsub("\n", "")
        vim.fn.system(string.format("tmux select-pane -t '%s:dev.3'", session_name))
        vim.notify("Focused terminal pane", vim.log.levels.INFO)
    end
end

M.focus_claude_pane = function()
    if in_tmux() then
        -- Navigate to claude-code pane (pane 2 - lower right)
        local session_name = vim.fn.system("tmux display-message -p '#S'"):gsub("\n", "")
        vim.fn.system(string.format("tmux select-pane -t '%s:dev.2'", session_name))
        vim.notify("Focused claude-code pane", vim.log.levels.INFO)
    end
end

M.focus_neovim_pane = function()
    if in_tmux() then
        -- Navigate back to neovim pane (pane 1 - left)
        local session_name = vim.fn.system("tmux display-message -p '#S'"):gsub("\n", "")
        vim.fn.system(string.format("tmux select-pane -t '%s:dev.1'", session_name))
        vim.notify("Focused neovim pane", vim.log.levels.INFO)
    end
end

M.new_floating_terminal = function()
    if in_tmux() then
        local session_name = vim.fn.system("tmux display-message -p '#S'"):gsub("\n", "")
        vim.fn.system(string.format("tmux display-popup -t '%s'", session_name))
    end
end

-- Debug function to show current layout
M.list_panes = function()
    if in_tmux() then
        vim.notify("Current tmux panes:", vim.log.levels.INFO)
        run_with_output('tmux list-panes -s', 'tmux Panes')
    else
        vim.notify("Not in tmux session", vim.log.levels.WARN)
    end
end

-- Function to manually send command to current pane
M.send_to_current_pane = function(cmd)
    if in_tmux() then
        vim.fn.system(string.format('tmux send-keys "%s" Enter', cmd))
        vim.notify("Sent to current pane: " .. cmd, vim.log.levels.INFO)
    else
        vim.notify("Not in tmux session", vim.log.levels.WARN)
    end
end

-- Simple watch command that uses current pane
M.watch_run_here = function()
    if in_tmux() then
        local project_dir = find_project_dir()
        vim.fn.system('tmux send-keys "clear" Enter')
        vim.fn.system(string.format('tmux send-keys "cd \\"%s\\"" Enter', project_dir))
        vim.fn.system('tmux send-keys "dotnet watch run" Enter')
        vim.notify("Started dotnet watch run in current pane", vim.log.levels.INFO)
    else
        run_with_output("dotnet watch run", "Watch Run")
    end
end

-- Toggle between popup styles
M.set_popup_style = function(style)
    if style == "float" then
        M._popup_style = "float"
        vim.notify("Using floating popups", vim.log.levels.INFO)
    elseif style == "split" then
        M._popup_style = "split"
        vim.notify("Using split popups", vim.log.levels.INFO)
    end
end

-- Initialize popup style
M._popup_style = "float"

-- Override run functions based on style
local original_run_in_popup = run_in_popup
run_in_popup = function(cmd, title)
    if M._popup_style == "split" then
        run_with_output(cmd, title)
    else
        original_run_in_popup(cmd, title)
    end
end

-- Setup function
M.setup = function()
    if vim.g.dotnet_setup_done then
        return
    end

    -- Basic commands (all use popups except watch)
    vim.keymap.set("n", "<leader>dr", M.run, { desc = "Run .NET project (popup)" })
    vim.keymap.set("n", "<leader>db", M.build, { desc = "Build .NET project (popup)" })
    vim.keymap.set("n", "<leader>dt", M.test, { desc = "Test .NET project (popup)" })
    vim.keymap.set("n", "<leader>dc", M.clean, { desc = "Clean .NET project (popup)" })
    vim.keymap.set("n", "<leader>dR", M.restore, { desc = "Restore packages (popup)" })

    -- Watch commands (go to tmux panes if available)
    vim.keymap.set("n", "<leader>dw", M.watch_run, { desc = "Start dotnet watch run (tmux pane)" })
    vim.keymap.set("n", "<leader>dW", M.watch_test, { desc = "Start dotnet watch test (tmux pane)" })
    vim.keymap.set("n", "<leader>ds", M.stop_watch, { desc = "Stop watch (tmux)" })

    -- Package management (popups)
    vim.keymap.set("n", "<leader>dpa", M.add_package, { desc = "Add NuGet package (popup)" })
    vim.keymap.set("n", "<leader>dpr", M.remove_package, { desc = "Remove NuGet package (popup)" })
    vim.keymap.set("n", "<leader>dpl", M.list_packages, { desc = "List NuGet packages (popup)" })

    -- Entity Framework (popups)
    vim.keymap.set("n", "<leader>dem", M.ef_add_migration, { desc = "Add EF migration (popup)" })
    vim.keymap.set("n", "<leader>deu", M.ef_update_database, { desc = "Update EF database (popup)" })
    vim.keymap.set("n", "<leader>der", M.ef_remove_migration, { desc = "Remove last EF migration (popup)" })
    vim.keymap.set("n", "<leader>del", M.ef_list_migrations, { desc = "List EF migrations (popup)" })

    -- tmux integration
    if in_tmux() then
        vim.keymap.set("n", "<leader>dfw", M.focus_watch_pane, { desc = "Focus terminal pane" })
        vim.keymap.set("n", "<leader>dfc", M.focus_claude_pane, { desc = "Focus claude-code pane" })
        vim.keymap.set("n", "<leader>dfn", M.focus_neovim_pane, { desc = "Focus neovim pane" })
        vim.keymap.set("n", "<leader>dft", M.new_floating_terminal, { desc = "New floating terminal (tmux)" })

        -- Debug commands
        vim.keymap.set("n", "<leader>dlp", M.list_panes, { desc = "List tmux panes (debug)" })
        vim.keymap.set("n", "<leader>dwh", M.watch_run_here, { desc = "Watch run in current pane" })
        vim.keymap.set("n", "<leader>dsc", function()
            vim.ui.input({prompt = "Command: "}, function(cmd)
                if cmd then M.send_to_current_pane(cmd) end
            end)
        end, { desc = "Send command to current pane" })
    end

    -- Popup style toggle
    vim.keymap.set("n", "<leader>dps", function()
        M.set_popup_style(M._popup_style == "float" and "split" or "float")
    end, { desc = "Toggle popup style (float/split)" })

    -- Quick access
    vim.keymap.set("n", "<F5>", M.run, { desc = "Quick run (popup)" })
    vim.keymap.set("n", "<F6>", M.build, { desc = "Quick build (popup)" })
    vim.keymap.set("n", "<F7>", M.test, { desc = "Quick test (popup)" })
    vim.keymap.set("n", "<F8>", M.watch_run, { desc = "Quick watch (tmux pane)" })

    -- Show environment info
    if in_tmux() then
        vim.notify("🚀 .NET + tmux integration loaded (1-based panes)", vim.log.levels.INFO)
    else
        vim.notify("🔧 .NET integration loaded (no tmux)", vim.log.levels.INFO)
    end

    vim.g.dotnet_setup_done = true
end

-- Auto-setup when loaded
vim.defer_fn(M.setup, 100)

return M
