-- Editor context for coding agents (Claude Code, Codex, ...) running in a pane
-- next to Neovim: the file you are in, the cursor and the last visual
-- selection. Neovim writes a small JSON snapshot whenever that changes;
-- bin/agent-editor-context reads it from an agent hook. A file, not RPC, so it
-- works from any Rex pane or terminal and nothing breaks if Neovim is gone.
--
-- Snapshots: stdpath("state")/editor-context/<pid>.json, removed on exit.
local M = {}

local MAX_SEL_LINES, MAX_SEL_CHARS = 80, 4000

local dir = vim.fn.stdpath("state") .. "/editor-context"
local path = ("%s/%d.json"):format(dir, vim.fn.getpid())
local last_json ---@type string?
local last_sel ---@type { buf: integer, from: integer, to: integer, cursor: integer[] }?

local function is_file(buf)
	return vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

--- The visual selection while in visual mode, else the last one as long as
--- the cursor has not moved since.
local function selection(buf)
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local a, b = vim.fn.line("v"), vim.fn.line(".")
		return math.min(a, b), math.max(a, b)
	end
	local s = last_sel
	if s and s.buf == buf and vim.deep_equal(s.cursor, vim.api.nvim_win_get_cursor(0)) then
		return s.from, s.to
	end
end

local function snapshot()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	-- Keep the last file snapshot while in terminals, pickers and floats.
	if not is_file(buf) or vim.api.nvim_win_get_config(win).relative ~= "" then
		return
	end
	local cursor = vim.api.nvim_win_get_cursor(win)
	local ctx = {
		pid = vim.fn.getpid(),
		cwd = vim.fn.getcwd(),
		file = vim.fs.normalize(vim.api.nvim_buf_get_name(buf)),
		filetype = vim.bo[buf].filetype,
		line = cursor[1],
		col = cursor[2] + 1,
		line_count = vim.api.nvim_buf_line_count(buf),
		modified = vim.bo[buf].modified,
	}
	local from, to = selection(buf)
	if from then
		ctx.selection = { from = from, to = to }
		local lines = vim.api.nvim_buf_get_lines(buf, from - 1, to, false)
		local text = table.concat(lines, "\n")
		if #lines <= MAX_SEL_LINES and #text <= MAX_SEL_CHARS then
			ctx.selection.text = text
		end
	end
	return ctx
end

local function write()
	local ok, ctx = pcall(snapshot)
	if not ok or not ctx then
		return
	end
	local json = vim.json.encode(ctx)
	if json == last_json then
		return
	end
	last_json = json
	ctx.time = os.time()
	vim.fn.mkdir(dir, "p")
	-- Write then rename, so a reader never sees half a file.
	local tmp = path .. ".tmp"
	local f = io.open(tmp, "w")
	if f then
		f:write(vim.json.encode(ctx))
		f:close()
		os.rename(tmp, path)
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("raphaelluethy-editor-context", { clear = true })
	-- CursorHold: 'updatetime' after the cursor stops. FocusLost: switching to
	-- the agent pane (Rex / terminals with focus reporting).
	vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "FocusLost", "BufWritePost", "VimSuspend" }, {
		group = group,
		callback = write,
	})
	-- Remember the selection when visual mode ends.
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = "[vV\22]:*",
		callback = function()
			local from, to = vim.fn.line("'<"), vim.fn.line("'>")
			if from > 0 then
				last_sel = {
					buf = vim.api.nvim_get_current_buf(),
					from = from,
					to = to,
					cursor = vim.api.nvim_win_get_cursor(0),
				}
			end
			write()
		end,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			os.remove(path)
		end,
	})
end

return M
