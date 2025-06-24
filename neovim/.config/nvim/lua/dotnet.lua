-- Enhanced .NET integration for Neovim with tmux
-- Save as ~/.config/nvim/lua/dotnet.lua

local M = {}

-- Function to check if we're running inside tmux
local function is_in_tmux()
    return vim.env.TMUX ~= nil
end

-- Function to find the project root (looks for .csproj, .sln, or .git)
local function find_project_root()
    local current_dir = vim.fn.expand('%:p:h')
    local root_patterns = { '*.csproj', '*.sln', '.git' }

    for _, pattern in ipairs(root_patterns) do
        local found = vim.fn.findfile(pattern, current_dir .. ';')
        if found ~= '' then
            return vim.fn.fnamemodify(found, ':h')
        end
    end

    -- Fallback to current working directory
    return vim.fn.getcwd()
end

-- Function to get the .csproj file in current directory or subdirectories
local function find_csproj_file()
    local project_root = find_project_root()
    local csproj_files = vim.fn.glob(project_root .. '/**/*.csproj', false, true)

    if #csproj_files > 0 then
        return vim.fn.fnamemodify(csproj_files[1], ':h')
    end

    return project_root
end

-- Function to get current tmux session info
local function get_tmux_session_info()
    if not is_in_tmux() then
        return nil
    end

    local cmd = "tmux display-message -p '#{session_name}:#{window_index}'"
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result:gsub("%s+", "")
end

-- Function to find or create a specific pane for dotnet output
local function get_or_create_dotnet_pane(pane_type)
    if not is_in_tmux() then
        return nil
    end

    local session_window = get_tmux_session_info()
    if not session_window then
        return nil
    end

    -- Map pane types to expected pane numbers in our layout
    local pane_map = {
        ["run"] = "2",      -- dotnet-run pane
        ["build"] = "3",    -- dotnet-build pane
        ["watch"] = "4",    -- dotnet-watch pane
        ["test"] = "3"      -- use build pane for tests
    }

    local pane_num = pane_map[pane_type] or "2"
    local target_pane = session_window .. "." .. pane_num

    -- Check if the target pane exists
    local check_cmd = string.format("tmux list-panes -t '%s' -F '#{pane_index}' | grep -q '^%s$'", session_window, pane_num)
    local pane_exists = os.execute(check_cmd) == 0

    if not pane_exists then
        -- Create the pane layout if it doesn't exist
        vim.notify("Creating dotnet output panes...", vim.log.levels.INFO)

        -- Split current window to create output panes
        os.execute(string.format("tmux split-window -h -p 30 -t '%s' -c '%s'", session_window, find_csproj_file()))
        os.execute(string.format("tmux split-window -v -p 67 -t '%s.2'", session_window))
        os.execute(string.format("tmux split-window -v -p 50 -t '%s.3'", session_window))

        -- Set pane titles
        os.execute(string.format("tmux select-pane -t '%s.2' -T 'dotnet-run'", session_window))
        os.execute(string.format("tmux select-pane -t '%s.3' -T 'dotnet-build'", session_window))
        os.execute(string.format("tmux select-pane -t '%s.4' -T 'dotnet-watch'", session_window))

        -- Send initial messages
        os.execute(string.format("tmux send-keys -t '%s.2' 'clear && echo \"dotnet run output\"' Enter", session_window))
        os.execute(string.format("tmux send-keys -t '%s.3' 'clear && echo \"dotnet build/test output\"' Enter", session_window))
        os.execute(string.format("tmux send-keys -t '%s.4' 'clear && echo \"dotnet watch output\"' Enter", session_window))

        -- Return focus to editor (pane 1)
        os.execute(string.format("tmux select-pane -t '%s.1'", session_window))
    end

    return target_pane
end

-- Function to run dotnet commands in specific tmux panes
function M.run_dotnet_command(cmd, pane_type)
    local project_dir = find_csproj_file()

    if is_in_tmux() then
        local target_pane = get_or_create_dotnet_pane(pane_type)
        if target_pane then
            -- Send Ctrl+L to clear screen, then change directory and run command
            local cd_cmd = string.format("cd '%s'", project_dir)
            os.execute(string.format("tmux send-keys -t '%s' C-l", target_pane))
            os.execute(string.format("tmux send-keys -t '%s' '%s' Enter", target_pane, cd_cmd))
            os.execute(string.format("tmux send-keys -t '%s' '%s' Enter", target_pane, cmd))
            vim.notify(string.format("Running: %s", cmd), vim.log.levels.INFO)
        else
            vim.notify("Failed to create tmux pane", vim.log.levels.ERROR)
        end
    else
        -- Fallback: run in terminal if not in tmux
        vim.cmd(string.format("terminal cd '%s' && %s", project_dir, cmd))
    end
end

-- Specific .NET commands
function M.dotnet_run()
    M.run_dotnet_command("dotnet run", "run")
end

function M.dotnet_build()
    M.run_dotnet_command("dotnet build", "build")
end

function M.dotnet_test()
    M.run_dotnet_command("dotnet test", "test")
end

function M.dotnet_watch_run()
    M.run_dotnet_command("dotnet watch run", "watch")
end

function M.dotnet_watch_test()
    M.run_dotnet_command("dotnet watch test", "watch")
end

function M.dotnet_clean()
    M.run_dotnet_command("dotnet clean", "build")
end

function M.dotnet_restore()
    M.run_dotnet_command("dotnet restore", "build")
end

-- Function to stop dotnet watch processes
function M.stop_dotnet_watch()
    if is_in_tmux() then
        local session_window = get_tmux_session_info()
        if session_window then
            -- Send Ctrl+C to the watch pane
            os.execute(string.format("tmux send-keys -t '%s.4' C-c", session_window))
            vim.notify("Stopped dotnet watch processes", vim.log.levels.INFO)
        end
    end
end

-- Function to focus specific dotnet panes
function M.focus_dotnet_pane(pane_type)
    if not is_in_tmux() then
        vim.notify("Not running in tmux", vim.log.levels.WARN)
        return
    end

    local session_window = get_tmux_session_info()
    if not session_window then
        return
    end

    local pane_map = {
        ["run"] = "2",
        ["build"] = "3",
        ["watch"] = "4",
        ["test"] = "3"
    }

    local pane_num = pane_map[pane_type] or "2"
    local target_pane = session_window .. "." .. pane_num

    -- Check if pane exists first
    local check_cmd = string.format("tmux list-panes -t '%s' -F '#{pane_index}' | grep -q '^%s$'", session_window, pane_num)
    if os.execute(check_cmd) == 0 then
        os.execute(string.format("tmux select-pane -t '%s'", target_pane))
        vim.notify(string.format("Focused %s pane", pane_type), vim.log.levels.INFO)
    else
        vim.notify(string.format("Pane %s not found. Run a dotnet command first.", pane_type), vim.log.levels.WARN)
    end
end

-- Enhanced keymaps for .NET development
local keymap = vim.keymap

-- Basic .NET commands
keymap.set("n", "<leader>dr", M.dotnet_run, { desc = "Run .NET project" })
keymap.set("n", "<leader>db", M.dotnet_build, { desc = "Build .NET project" })
keymap.set("n", "<leader>dt", M.dotnet_test, { desc = "Test .NET project" })
keymap.set("n", "<leader>dc", M.dotnet_clean, { desc = "Clean .NET project" })
keymap.set("n", "<leader>dR", M.dotnet_restore, { desc = "Restore .NET packages" })

-- Watch commands (useful for development)
keymap.set("n", "<leader>dw", M.dotnet_watch_run, { desc = "Watch run .NET project" })
keymap.set("n", "<leader>dW", M.dotnet_watch_test, { desc = "Watch test .NET project" })
keymap.set("n", "<leader>ds", M.stop_dotnet_watch, { desc = "Stop dotnet watch" })

-- Pane focus commands
keymap.set("n", "<leader>df", function() M.focus_dotnet_pane("run") end, { desc = "Focus dotnet run pane" })
keymap.set("n", "<leader>dF", function() M.focus_dotnet_pane("build") end, { desc = "Focus dotnet build pane" })
keymap.set("n", "<leader>dg", function() M.focus_dotnet_pane("watch") end, { desc = "Focus dotnet watch pane" })

-- Quick project commands
keymap.set("n", "<F5>", M.dotnet_run, { desc = "Quick run .NET project" })
keymap.set("n", "<F6>", M.dotnet_build, { desc = "Quick build .NET project" })
keymap.set("n", "<F7>", M.dotnet_test, { desc = "Quick test .NET project" })

return M
