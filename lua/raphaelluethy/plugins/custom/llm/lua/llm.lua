local M = {}
local Job = require 'plenary.job'
local ns_id = vim.api.nvim_create_namespace 'llm_custom'
local telescope = require 'telescope.builtin'
M.history_folder_path = vim.fn.stdpath 'data' .. '/llm_history'
M.prompt_history = ''
M.response_history = ''

local function get_api_key(name)
    return os.getenv(name)
end

function M.save_history()
    local current_date = os.date '%Y-%m-%d'
    local current_time = os.date '%H:%M:%S'

    -- Use os.execute to create the directory if it doesn't exist
    os.execute('mkdir -p "' .. M.history_folder_path .. '"')

    local history_file_path = M.history_folder_path .. '/' .. current_date .. '.md'

    -- Use Lua's io module to write the content
    local file = io.open(history_file_path, 'a')
    if file then
        local content = '\n\n---\n\nCurrent Time: ' ..
            current_time ..
            '\n\nPrompt: \n\n' .. M.prompt_history .. '\n\nResponse: \n\n' .. M.response_history .. '\n\n'
        file:write(content)
        file:close()
    else
        print('Error saving history to: ' .. history_file_path)
    end

    -- Clear the history
    M.prompt_history = ''
    M.response_history = '\n\n---\n\n'
end

function M.search_llm_history_fuzzy()
    local folder_path = M.history_folder_path

    telescope.live_grep {
        prompt_title = 'Search in LLM History',
        cwd = folder_path,
        search_dirs = { folder_path },
        vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--hidden',
        },
    }
end

function M.search_llm_history_files()
    local folder_path = M.history_folder_path

    telescope.find_files {
        prompt_title = 'Search in LLM History',
        cwd = folder_path,
        search_dirs = { folder_path },
    }
end

function M.get_lines_until_cursor()
    local current_buffer = vim.api.nvim_get_current_buf()
    local current_window = vim.api.nvim_get_current_win()
    local cursor_position = vim.api.nvim_win_get_cursor(current_window)
    local row = cursor_position[1]

    local lines = vim.api.nvim_buf_get_lines(current_buffer, 0, row, true)

    return table.concat(lines, '\n')
end

function M.get_visual_selection()
    local mode = vim.fn.mode()
    if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
        print('Not in visual mode')
        return nil -- Return nil if not in visual mode
    end

    local _, srow, scol = unpack(vim.fn.getpos 'v')
    local _, erow, ecol = unpack(vim.fn.getpos '.')

    if mode == 'V' then
        if srow > erow then
            return vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
        else
            return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
        end
    end

    if mode == 'v' then
        if srow < erow or (srow == erow and scol <= ecol) then
            return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
        else
            return vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
        end
    end

    if mode == '\22' then
        local lines = {}
        if srow > erow then
            srow, erow = erow, srow
        end
        if scol > ecol then
            scol, ecol = ecol, scol
        end
        for i = srow, erow do
            table.insert(lines,
                vim.api.nvim_buf_get_text(0, i - 1, math.min(scol - 1, ecol), i - 1, math.max(scol - 1, ecol), {})[1])
        end
        return lines
    end
end

function M.write_string_at_extmark(str, extmark_id)
    vim.schedule(function()
        local extmark = vim.api.nvim_buf_get_extmark_by_id(0, ns_id, extmark_id, {
            details = false,
        })
        local row, col = extmark[1], extmark[2]

        vim.cmd 'undojoin'
        local lines = vim.split(str, '\n')
        vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
        M.response_history = M.response_history .. str
    end)
end

function M.write_string_at_cursor(str)
    vim.schedule(function()
        local current_window = vim.api.nvim_get_current_win()
        local cursor_position = vim.api.nvim_win_get_cursor(current_window)
        local row, col = cursor_position[1], cursor_position[2]

        local lines = vim.split(str, '\n')

        vim.cmd 'undojoin'
        vim.api.nvim_put(lines, 'c', true, true)

        local num_lines = #lines
        local last_line_length = #lines[num_lines]
        vim.api.nvim_win_set_cursor(current_window, { row + num_lines - 1, col + last_line_length })
        M.response_history = M.response_history .. str
    end)
end

function M.make_anthropic_spec_curl_args(opts, prompt, system_prompt)
    local url = opts.url
    local api_key = opts.api_key_name and get_api_key(opts.api_key_name)
    local data = {
        system = system_prompt,
        messages = { {
            role = 'user',
            content = prompt,
        } },
        model = opts.model,
        stream = true,
        max_tokens = 4096,
    }
    local args = { '-N', '-X', 'POST', '-H', 'Content-Type: application/json', '-d', vim.json.encode(data) }
    if api_key then
        table.insert(args, '-H')
        table.insert(args, 'x-api-key: ' .. api_key)
        table.insert(args, '-H')
        table.insert(args, 'anthropic-version: 2023-06-01')
    end
    table.insert(args, url)
    return args
end

function M.make_openai_spec_curl_args(opts, prompt, system_prompt)
    local url = opts.url
    local api_key = opts.api_key_name and get_api_key(opts.api_key_name)
    local data = {
        messages = {
            {
                role = 'system',
                content = system_prompt,
            },
            {
                role = 'user',
                content = prompt,
            },
        },
        model = opts.model,
        temperature = 0.7,
        stream = true,
    }
    local args = { '-N', '-X', 'POST', '-H', 'Content-Type: application/json', '-d', vim.json.encode(data) }
    if api_key then
        table.insert(args, '-H')
        table.insert(args, 'Authorization: Bearer ' .. api_key)
    end
    table.insert(args, url)
    return args
end

function M.make_ollama_spec_curl_args(opts, prompt, system_prompt)
    local url = opts.url
    local data = {
        model = opts.model,
        messages = {
            {
                role = 'system',
                content = system_prompt,
            },
            {
                role = 'user',
                content = prompt,
            },
        },
    }
    local args = { '-d', vim.json.encode(data) }
    table.insert(args, url)
    return args
end

local function get_prompt(opts, visual_lines)
    local replace = opts.replace
    if visual_lines == nil then
        visual_lines = M.get_visual_selection()
    end
    local prompt = ''
    local file_type = vim.api.nvim_get_option_value('filetype', {})

    if visual_lines then
        -- embed the visual lines in the prompt in a code block with a language hint
        prompt = '```' .. file_type .. '\n' .. table.concat(visual_lines, '\n') .. '\n```'
        if replace then
            vim.api.nvim_command 'normal! c'
        else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', false, true, true), 'nx', false)
        end
    else
        prompt = M.get_lines_until_cursor()
    end


    if file_type ~= 'file_type' then
        prompt = prompt .. '\n\nThe file type is: `' .. file_type .. '` , use it as context.'
    end
    M.prompt_history = prompt
    return prompt
end

function M.handle_anthropic_spec_data(data_stream, float, extmark_id, event_state)
    if event_state == 'content_block_delta' then
        local json = vim.json.decode(data_stream)
        if json.delta and json.delta.text then
            if not float then
                M.write_string_at_extmark(json.delta.text, extmark_id)
            else
                M.write_string_at_cursor(json.delta.text)
            end
        end
    end
end

function M.handle_openai_spec_data(data_stream, float, extmark_id)
    if data_stream:match '"delta":' then
        local json = vim.json.decode(data_stream)
        if json.choices and json.choices[1] and json.choices[1].delta then
            local content = json.choices[1].delta.content
            if content then
                if not float then
                    M.write_string_at_extmark(content, extmark_id)
                else
                    M.write_string_at_cursor(content)
                end
            end
        end
    end
end

function M.handle_ollama_spec_data(data_stream, float, extmark_id)
    local json = vim.json.decode(data_stream)
    if json.done then
        return
    end
    if json.message and json.message.content then
        if not float then
            M.write_string_at_extmark(json.message.content, extmark_id)
        else
            M.write_string_at_cursor(json.message.content)
        end
    end
end

local group = vim.api.nvim_create_augroup('DING_LLM_AutoGroup', {
    clear = true,
})
local active_job = nil

function M.invoke_llm_and_stream_into_editor(opts, make_curl_args_fn, handle_data_fn)
    vim.api.nvim_clear_autocmds {
        group = group,
    }
    local prompt = get_prompt(opts)
    local system_prompt = opts.system_prompt or
        'You are a tsundere uwu anime. Yell at me for not setting my configuration for my llm plugin correctly'
    local args = make_curl_args_fn(opts, prompt, system_prompt)
    local curr_event_state = nil
    local crow, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local stream_end_extmark_id = vim.api.nvim_buf_set_extmark(0, ns_id, crow - 1, -1, {})

    local function parse_and_call(line)
        local event = line:match '^event: (.+)$'
        if event then
            curr_event_state = event
            return
        end
        local data_match = line:match '^data: (.+)$'
        if data_match then
            handle_data_fn(data_match, false, stream_end_extmark_id, curr_event_state)
        end
        local ollama_data_match = line:match '"message":(%b{})'
        if ollama_data_match then
            handle_data_fn(line, false, stream_end_extmark_id, curr_event_state)
        end
    end

    if active_job then
        active_job:shutdown()
        active_job = nil
    end

    active_job = Job:new {
        command = 'curl',
        args = args,
        on_stdout = function(_, out)
            parse_and_call(out)
        end,
        on_stderr = function(_, _) end,
        on_exit = function()
            active_job = nil
        end,
    }

    active_job:start()

    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'LLM_ESCAPE',
        callback = function()
            if active_job then
                active_job:shutdown()
                print 'LLM streaming cancelled'
                active_job = nil
            end
        end,
    })

    vim.api.nvim_set_keymap('n', '<Esc>', ':doautocmd User LLM_ESCAPE<CR>', {
        noremap = true,
        silent = true,
    })
    return active_job
end

function M.invoke_llm_and_stream_into_float(opts, make_curl_args_fn, handle_data_fn)
    vim.api.nvim_clear_autocmds {
        group = group,
    }
    local visual_selection = M.get_visual_selection()
    -- Create a floating input for additional prompt
    local input_buf = vim.api.nvim_create_buf(false, true)
    local input_width = math.floor(vim.o.columns * 0.6)
    local input_height = 1
    local input_win = vim.api.nvim_open_win(input_buf, true, {
        relative = 'editor',
        width = input_width,
        height = input_height,
        col = math.floor((vim.o.columns - input_width) / 2),
        row = math.floor(vim.o.lines * 0.4),
        style = 'minimal',
        border = 'rounded',
        title = 'Additional Prompt (Press Enter to submit, leave empty to proceed)',
    })
    vim.api.nvim_buf_set_option(input_buf, 'buftype', 'prompt')
    vim.fn.prompt_setprompt(input_buf, '')
    vim.cmd 'startinsert'

    local function on_input_submit()
        local additional_prompt = vim.trim(vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)[1] or '')
        vim.api.nvim_win_close(input_win, true)
        vim.api.nvim_buf_delete(input_buf, {
            force = true,
        }) -- Delete the input buffer

        local prompt = get_prompt(opts, visual_selection)
        if additional_prompt ~= '' then
            prompt = prompt ..
                '\nHere are your instructions, follow them without leaving anything out: \n\n' .. additional_prompt
        end
        local system_prompt = opts.system_prompt or
            'You are a tsundere uwu anime. Yell at me for not setting my configuration for my llm plugin correctly'
        local args = make_curl_args_fn(opts, prompt, system_prompt)
        local curr_event_state = nil

        -- Create a floating window for output
        local buf = vim.api.nvim_create_buf(false, true)
        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.8)
        local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            col = math.floor((vim.o.columns - width) / 2),
            row = math.floor((vim.o.lines - height) / 2),
            style = 'minimal',
            border = 'rounded',
            title = 'LLM Streaming',
        })
        vim.api.nvim_set_option_value('filetype', 'markdown', {
            buf = buf,
        })

        local function append_to_float(text)
            vim.schedule(function()
                local lines = vim.split(text, '\n')
                vim.api.nvim_set_option_value('modifiable', true, {})
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
                vim.api.nvim_set_option_value('modifiable', false, {})
                vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
            end)
        end

        local start_text = '\n\nPrompt: \n\n'
        local end_text = '\n\nResponse: \n\n'

        M.write_string_at_cursor(start_text .. prompt .. end_text)

        local function parse_and_call(line)
            local event = line:match '^event: (.+)$'
            if event then
                curr_event_state = event
                return
            end
            local data_match = line:match '^data: (.+)$'
            if data_match then
                handle_data_fn(data_match, true, append_to_float, curr_event_state)
            end
            local ollama_data_match = line:match '"message":(%b{})'
            if ollama_data_match then
                handle_data_fn(line, true, append_to_float, curr_event_state)
            end
        end

        if active_job then
            active_job:shutdown()
            active_job = nil
        end

        active_job = Job:new {
            command = 'curl',
            args = args,
            on_stdout = function(_, out)
                parse_and_call(out)
            end,
            on_stderr = function(_, _) end,
            on_exit = function()
                active_job = nil
                M.save_history()
            end,
        }

        active_job:start()

        vim.api.nvim_create_autocmd('User', {
            group = group,
            pattern = 'FLOAT_LLM_ESCAPE',
            callback = function()
                if active_job then
                    active_job:shutdown()
                    M.response_history = M.response_history .. '\n\nLLM streaming cancelled'
                    M.save_history()
                    print 'LLM streaming cancelled'
                    active_job = nil
                end
            end,
        })

        vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':doautocmd User FLOAT_LLM_ESCAPE<CR>', {
            noremap = true,
            silent = true,
        })
    end

    vim.keymap.set('i', '<CR>', function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
        on_input_submit()
    end, {
        buffer = input_buf,
        noremap = true,
        silent = true,
    })

    return active_job
end

return M
