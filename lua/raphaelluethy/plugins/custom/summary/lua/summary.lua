local M = {}
local Job = require 'plenary.job'
local api = vim.api

--- The branch to compare against
M.branch = 'develop'

--- Retrieves the commits between the current HEAD and the specified branch
-- @return table A table of lines containing the full git log output
function M.get_commits()
    local cmd = string.format('git log --patch $(git merge-base HEAD %s)..HEAD', M.branch)
    local output = {}

    Job:new({
        command = 'bash',
        args = { '-c', cmd },
        on_stdout = function(_, line)
            table.insert(output, line)
        end,
    }):sync()

    return output
end

--- Generates a summary of commits and displays it in a new buffer
function M.generate_summary()
    local output = M.get_commits()

    -- Create a new temporary buffer
    local buf = api.nvim_create_buf(false, true)

    -- Set buffer options
    api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    api.nvim_buf_set_option(buf, 'swapfile', false)
    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- Populate the buffer with the full git log output
    api.nvim_buf_set_lines(buf, 0, -1, false, output)

    -- Open the buffer in a new window
    api.nvim_command 'split'
    api.nvim_win_set_buf(0, buf)

    -- Set additional buffer options
    api.nvim_buf_set_option(buf, 'modifiable', false)
    api.nvim_buf_set_option(buf, 'filetype', 'git')
end

--- Sets up the module with the provided options
-- @param opts table Configuration options
-- @param opts.branch string The branch to compare against
-- @return table The module
function M.setup(opts)
    M.branch = opts.branch or 'develop'
    return M
end

return M
