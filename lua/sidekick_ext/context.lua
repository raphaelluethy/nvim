-- Editor context for agent CLIs: the file you're in, the cursor, the visual
-- selection and the other visible files. Agents ask for it on every prompt
-- through a hook (bin/agent-editor-context) that connects to this Neovim over
-- RPC ($SIDEKICK_NVIM, else $NVIM) and calls M.text(cwd).
--
-- Focus is usually in the agent terminal when you submit a prompt, so the
-- "current file" is the file window you were in last, not the current window.
local M = {}

M.config = {
	max_selection_lines = 80,
	max_selection_chars = 4000,
	max_other_files = 8,
}

local recent = {} ---@type integer[] file windows, most recently entered first
---@type { buf: integer, win: integer, from: integer, to: integer, cursor: integer[] }?
local last_sel

local function is_file(buf)
	return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function is_file_win(win)
	return win
		and vim.api.nvim_win_is_valid(win)
		and vim.api.nvim_win_get_config(win).relative == ""
		and is_file(vim.api.nvim_win_get_buf(win))
end

--- Path relative to cwd when inside it, else ~-relative.
local function display(path, cwd)
	path = vim.fs.normalize(path)
	cwd = cwd and vim.fs.normalize(cwd)
	if cwd and path:sub(1, #cwd + 1) == cwd .. "/" then
		return path:sub(#cwd + 2)
	end
	return vim.fn.fnamemodify(path, ":~")
end

--- The file window the user is working in.
---@return integer?
local function file_win()
	local cur = vim.api.nvim_get_current_win()
	if is_file_win(cur) then
		return cur
	end
	for _, win in ipairs(recent) do
		if is_file_win(win) then
			return win
		end
	end
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if is_file_win(win) then
			return win
		end
	end
end

--- Visual selection in win as a line range: live if still in visual mode,
--- otherwise the last one, as long as the cursor hasn't moved since.
---@return integer? from, integer? to
local function selection(win)
	local buf = vim.api.nvim_win_get_buf(win)
	local mode = vim.fn.mode()
	if win == vim.api.nvim_get_current_win() and (mode == "v" or mode == "V" or mode == "\22") then
		local a, b = vim.fn.line("v"), vim.fn.line(".")
		return math.min(a, b), math.max(a, b)
	end
	local s = last_sel
	if s and s.win == win and s.buf == buf and vim.deep_equal(vim.api.nvim_win_get_cursor(win), s.cursor) then
		return s.from, s.to
	end
end

--- Context lines for the agent, or nil when there is no file open.
---@param cwd? string agent working directory (paths are shown relative to it)
---@return string?
function M.text(cwd)
	local win = file_win()
	if not win then
		return
	end
	local buf = vim.api.nvim_win_get_buf(win)
	local name = vim.api.nvim_buf_get_name(buf)
	local cursor = vim.api.nvim_win_get_cursor(win)
	local ft = vim.bo[buf].filetype
	local cfg = M.config

	local out = {
		"The user is working in Neovim. Editor state at the time of this message (use it to resolve references like"
			.. ' "this file", "here" or "the selection"; ignore it when unrelated):',
		("- Current file: %s (line %d of %d, column %d)%s"):format(
			display(name, cwd),
			cursor[1],
			vim.api.nvim_buf_line_count(buf),
			cursor[2] + 1,
			vim.bo[buf].modified and " — has unsaved changes, the file on disk may differ" or ""
		),
	}

	local from, to = selection(win)
	if from then
		local lines = vim.api.nvim_buf_get_lines(buf, from - 1, to, false)
		local text = table.concat(lines, "\n")
		if #lines <= cfg.max_selection_lines and #text <= cfg.max_selection_chars then
			out[#out + 1] = ("- Selected lines %d-%d:"):format(from, to)
			out[#out + 1] = "```" .. ft
			out[#out + 1] = text
			out[#out + 1] = "```"
		else
			out[#out + 1] = ("- Selected lines %d-%d (too long to include)"):format(from, to)
		end
	end

	local others, seen = {}, { [buf] = true }
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local b = vim.api.nvim_win_get_buf(w)
		if is_file_win(w) and not seen[b] and #others < cfg.max_other_files then
			seen[b] = true
			others[#others + 1] = display(vim.api.nvim_buf_get_name(b), cwd)
		end
	end
	if #others > 0 then
		out[#out + 1] = "- Also visible: " .. table.concat(others, ", ")
	end
	return table.concat(out, "\n")
end

--- The file the user is working in, as an editor selection (Claude Code IDE
--- protocol, 0-based positions): the visual selection by whole lines, else an
--- empty selection at the cursor. Nil when no file is open.
---@return { filePath: string, text: string, selection: { start: { line: integer, character: integer }, ["end"]: { line: integer, character: integer } } }?
function M.selection()
	local win = file_win()
	if not win then
		return
	end
	local buf = vim.api.nvim_win_get_buf(win)
	local ret = { filePath = vim.fs.normalize(vim.api.nvim_buf_get_name(buf)) }
	local from, to = selection(win)
	if from then
		local lines = vim.api.nvim_buf_get_lines(buf, from - 1, to, false)
		ret.text = table.concat(lines, "\n")
		ret.selection = {
			start = { line = from - 1, character = 0 },
			["end"] = { line = to - 1, character = #(lines[#lines] or "") },
		}
	else
		local cursor = vim.api.nvim_win_get_cursor(win)
		local pos = { line = cursor[1] - 1, character = cursor[2] }
		ret.text = ""
		ret.selection = { start = pos, ["end"] = pos }
	end
	return ret
end

function M.setup()
	local group = vim.api.nvim_create_augroup("sidekick_ext.context", { clear = true })
	vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
		group = group,
		callback = function()
			local win = vim.api.nvim_get_current_win()
			if is_file_win(win) then
				-- Keep a short history: a window can turn into a terminal later.
				recent = vim.tbl_filter(function(w)
					return w ~= win and vim.api.nvim_win_is_valid(w)
				end, recent)
				table.insert(recent, 1, win)
				recent[11] = nil
			end
		end,
	})
	-- Remember the selection when visual mode ends ('< and '> are set by then).
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = { "[vV\22]:*" },
		callback = function()
			local win = vim.api.nvim_get_current_win()
			local buf = vim.api.nvim_win_get_buf(win)
			if not is_file(buf) then
				return
			end
			local from, to = vim.fn.line("'<"), vim.fn.line("'>")
			if from > 0 and to > 0 then
				last_sel = { buf = buf, win = win, from = from, to = to, cursor = vim.api.nvim_win_get_cursor(win) }
			end
		end,
	})
end

return M
