-- Simple .NET integration for Neovim
-- Save as ~/.config/nvim/lua/dotnet.lua
-- This version prevents timing conflicts

local M = {}

-- Only set up if not already done
if vim.g.dotnet_setup_done then
    return M
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

-- Create popup window
local function create_popup(title)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = title,
        title_pos = 'center'
    }

    local win = vim.api.nvim_open_win(buf, true, opts)
    return buf, win
end

-- Run command in popup
local function run_popup_cmd(cmd, title)
    local project_dir = find_project_dir()
    local buf, win = create_popup(title)

    local full_cmd = string.format("cd '%s' && %s", project_dir, cmd)
    vim.fn.termopen(full_cmd)

    -- Close keymaps
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })

    vim.keymap.set('t', '<Esc><Esc>', function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf })

    vim.cmd('startinsert')
end

-- Run command in tmux watch pane
local function run_watch_cmd(cmd)
    if not vim.env.TMUX then
        run_popup_cmd(cmd, "Watch")
        return
    end

    local project_dir = find_project_dir()
    local session_window = vim.fn.system("tmux display-message -p '#{session_name}:#{window_index}'"):gsub("%s+", "")
    local watch_pane = session_window .. ".3"

    -- Check if watch pane exists
    local check_cmd = string.format("tmux list-panes -t '%s' | grep -q '^3:'", session_window)
    if os.execute(check_cmd) ~= 0 then
        vim.notify("Watch pane not found", vim.log.levels.WARN)
        run_popup_cmd(cmd, "Watch")
        return
    end

    -- Run in watch pane
    os.execute(string.format("tmux send-keys -t '%s' C-c", watch_pane))
    os.execute(string.format("tmux send-keys -t '%s' 'cd \"%s\"' Enter", watch_pane, project_dir))
    os.execute(string.format("tmux send-keys -t '%s' '%s' Enter", watch_pane, cmd))

    vim.notify("Started: " .. cmd, vim.log.levels.INFO)
end

-- .NET Commands
M.run = function() run_popup_cmd("dotnet run", "🚀 Run") end
M.build = function() run_popup_cmd("dotnet build", "🔨 Build") end
M.test = function() run_popup_cmd("dotnet test", "🧪 Test") end
M.clean = function() run_popup_cmd("dotnet clean", "🧹 Clean") end
M.restore = function() run_popup_cmd("dotnet restore", "📦 Restore") end

M.watch_run = function() run_watch_cmd("dotnet watch run") end
M.watch_test = function() run_watch_cmd("dotnet watch test") end
M.stop_watch = function()
    if vim.env.TMUX then
        local session_window = vim.fn.system("tmux display-message -p '#{session_name}:#{window_index}'"):gsub("%s+", "")
        os.execute(string.format("tmux send-keys -t '%s.3' C-c", session_window))
        vim.notify("Stopped watch", vim.log.levels.INFO)
    end
end

-- Delayed keymap setup to avoid timing conflicts
local function setup_keymaps()
    if vim.g.dotnet_setup_done then
        return
    end

    vim.keymap.set("n", "<leader>dr", M.run, { desc = "Run .NET project" })
    vim.keymap.set("n", "<leader>db", M.build, { desc = "Build .NET project" })
    vim.keymap.set("n", "<leader>dt", M.test, { desc = "Test .NET project" })
    vim.keymap.set("n", "<leader>dc", M.clean, { desc = "Clean .NET project" })
    vim.keymap.set("n", "<leader>dR", M.restore, { desc = "Restore packages" })

    vim.keymap.set("n", "<leader>dw", M.watch_run, { desc = "Watch run" })
    vim.keymap.set("n", "<leader>dW", M.watch_test, { desc = "Watch test" })
    vim.keymap.set("n", "<leader>ds", M.stop_watch, { desc = "Stop watch" })

    vim.keymap.set("n", "<F5>", M.run, { desc = "Quick run" })
    vim.keymap.set("n", "<F6>", M.build, { desc = "Quick build" })
    vim.keymap.set("n", "<F7>", M.test, { desc = "Quick test" })
    vim.keymap.set("n", "<F8>", M.watch_run, { desc = "Quick watch" })

    vim.g.dotnet_setup_done = true
end

-- Delay setup to avoid conflicts with lazy.nvim
vim.defer_fn(setup_keymaps, 100)

return M
