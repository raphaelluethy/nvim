-- Review comments: annotate lines / ranges (also in codediff's revision
-- panes), then copy them all to the clipboard as one Markdown block. Comments
-- persist per repo + branch and follow the code while you edit (extmarks).
local M = {}

local ns = vim.api.nvim_create_namespace("review_comments")
local data_dir = vim.fn.stdpath("data") .. "/review-comments"

M.config = {
	sign = "▍",
	header = "Please address these code review comments:",
}

---@class review.Comment
---@field id integer
---@field file string path relative to the repo root
---@field kind "line"|"char"|"point" linewise selection, charwise selection, or cursor position
---@field lnum integer 1-based
---@field col integer 0-based byte column
---@field end_lnum integer 1-based
---@field end_col integer 0-based byte column, exclusive (char) / cursor column (point)
---@field text string
---@field old? { range: string, lines: string[] } the old code when the comment was made on a revision pane

--- Multi-line comment editor in a float. <C-s> (or <CR> in normal mode)
--- saves, q / <Esc> in normal mode cancels.
---@param opts { title: string, default?: string }
---@param on_submit fun(text: string)
local function input(opts, on_submit)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"
	if opts.default then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(opts.default, "\n", { plain = true }))
	end
	local width = math.min(80, math.floor(vim.o.columns * 0.8))
	local height = math.min(12, math.floor(vim.o.lines * 0.4))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " " .. opts.title .. " ",
		footer = " <C-s> save · q cancel ",
		footer_pos = "right",
	})
	vim.wo[win].wrap = true
	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	local function submit()
		local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
		vim.cmd.stopinsert()
		close()
		if text ~= "" then
			on_submit(text)
		end
	end
	local function map(mode, lhs, fn)
		vim.keymap.set(mode, lhs, fn, { buffer = buf, nowait = true })
	end
	map({ "n", "i" }, "<C-s>", submit)
	map("n", "<CR>", submit)
	map("n", "q", close)
	map("n", "<Esc>", close)
	if not opts.default then
		vim.cmd.startinsert()
	end
end

---@type { key: string?, root: string?, comments: review.Comment[], next_id: integer }
local store = { comments = {}, next_id = 1 }
local current_text ---@type fun(c: review.Comment): string[]

local function repo()
	local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
	local res = vim.system({ "git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD" }, { text = true }):wait()
	local branch = res.code == 0 and vim.trim(res.stdout) or "nogit"
	return root, branch
end

local function store_path(key)
	return data_dir .. "/" .. key:gsub("[/\\:%s]", "%%") .. ".json"
end

local function load()
	local root, branch = repo()
	local key = root .. "@" .. branch
	if store.key == key then
		return
	end
	store = { key = key, root = root, comments = {}, next_id = 1 }
	local f = io.open(store_path(key), "r")
	if f then
		local ok, data = pcall(vim.json.decode, f:read("*a"))
		f:close()
		if ok and type(data) == "table" then
			store.comments = data.comments or {}
			for _, c in ipairs(store.comments) do
				c.kind, c.col, c.end_col, c.code = c.kind or "line", c.col or 0, c.end_col or 0, nil
			end
			store.next_id = data.next_id or (#store.comments + 1)
		end
	end
end

local function save()
	vim.fn.mkdir(data_dir, "p")
	local f = io.open(store_path(store.key), "w")
	if f then
		f:write(vim.json.encode({ comments = store.comments, next_id = store.next_id }))
		f:close()
	end
end

local function rel(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" or name:match("^%a[%w+.-]*://") or vim.bo[buf].buftype ~= "" then
		return nil
	end
	return vim.fs.relpath(store.root, name) or name
end

local function abs(file)
	return vim.fs.joinpath(store.root, file)
end

--- In a codediff tab the left pane (and the right pane of a staged view) is a
--- virtual revision buffer. Resolve it to the working file and a line mapper
--- (old line → current line through codediff's diff result; lines that only
--- exist in the old version map to where they were removed).
---@return string? file, { map: fun(l: integer): integer, is_original: boolean, lines: fun(a: integer, b: integer): string[] }?
local function resolve_virtual(buf)
	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	if not ok then
		return nil
	end
	local tab = vim.api.nvim_get_current_tabpage()
	local s = lifecycle.get_session(tab)
	if not s or (s.original_bufnr ~= buf and s.modified_bufnr ~= buf) then
		return nil
	end
	local is_original = s.original_bufnr == buf and s.modified_bufnr ~= buf
	local path = (s.modified and s.modified.relative ~= "" and s.modified.relative) or (s.original and s.original.relative) or ""
	if path == "" then
		return nil
	end
	local changes = (s.stored_diff_result and s.stored_diff_result.changes) or {}
	local function map(l)
		if not is_original then
			return l
		end
		local shift = 0
		for _, c in ipairs(changes) do
			if l < c.original.start_line then
				break
			elseif l < c.original.end_line or (c.original.start_line == c.original.end_line and l == c.original.start_line) then
				return math.max(1, c.modified.start_line)
			end
			shift = (c.modified.end_line - c.original.end_line)
		end
		return math.max(1, l + shift)
	end
	return path, {
		is_original = is_original,
		map = map,
		lines = function(a, b)
			return vim.api.nvim_buf_get_lines(buf, a - 1, b, false)
		end,
	}
end

--- Pull current extmark positions back into the store (code may have moved).
local function sync_buf(buf)
	local file = rel(buf)
	if not file then
		return
	end
	for _, c in ipairs(store.comments) do
		if c.file == file then
			local m = vim.api.nvim_buf_get_extmark_by_id(buf, ns, c.id, { details = true })
			if m and m[1] then
				c.lnum, c.col = m[1] + 1, m[2]
				local d = m[3] or {}
				c.end_lnum = (d.end_row or m[1]) + 1
				if c.kind == "char" then
					c.end_col = d.end_col or c.end_col
				elseif c.kind == "point" then
					c.end_col = c.col
				end
			end
		end
	end
end

local function sync_all()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			sync_buf(buf)
		end
	end
end

local function render(buf)
	if not vim.api.nvim_buf_is_loaded(buf) then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	local file = rel(buf)
	if not file then
		return
	end
	local last = vim.api.nvim_buf_line_count(buf)
	local function clamp(row, col)
		local len = #(vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or "")
		return math.max(0, math.min(col or 0, len))
	end
	for _, c in ipairs(store.comments) do
		if c.file == file then
			local s = math.min(c.lnum, last) - 1
			local e = math.min(c.end_lnum, last) - 1
			-- Range mark: tracks the exact text (columns included) and shows the
			-- sign. Its id is the comment id.
			vim.api.nvim_buf_set_extmark(buf, ns, s, clamp(s, c.kind ~= "line" and c.col or 0), {
				id = c.id,
				end_row = e,
				end_col = clamp(e, c.kind == "char" and c.end_col or 0),
				hl_group = c.kind == "char" and "ReviewCommentRange" or nil,
				sign_text = M.config.sign,
				sign_hl_group = "DiagnosticSignInfo",
				right_gravity = false,
				end_right_gravity = true,
			})
			-- Display mark: the comment text below the range.
			local lines = {}
			for i, l in ipairs(vim.split(c.text, "\n", { plain = true })) do
				lines[#lines + 1] = { { (i == 1 and "  > " or "    ") .. l, "DiagnosticVirtualTextInfo" } }
			end
			-- Fixed id offset so it never collides with a comment's range-mark id.
			vim.api.nvim_buf_set_extmark(buf, ns, e, 0, { id = c.id + 1000000, virt_lines = lines })
		end
	end
end

local function rerender(file)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and (not file or rel(buf) == file) then
			render(buf)
		end
	end
end

--- Comment covering the cursor line in the current buffer.
local function at_cursor()
	load()
	sync_buf(0)
	local file, lnum = rel(0), vim.fn.line(".")
	for _, c in ipairs(store.comments) do
		if c.file == file and lnum >= c.lnum and lnum <= c.end_lnum then
			return c
		end
	end
end

--- Add a comment on the current line, or the visual range.
function M.add()
	load()
	local file, virtual = rel(0), nil
	if not file then
		file, virtual = resolve_virtual(vim.api.nvim_get_current_buf())
	end
	if not file then
		return vim.notify("Buffer has no file", vim.log.levels.WARN)
	end
	local cur = vim.api.nvim_win_get_cursor(0)
	---@type review.Comment
	local c = { kind = "point", lnum = cur[1], col = cur[2], end_lnum = cur[1], end_col = cur[2] }
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
		if a[2] > b[2] or (a[2] == b[2] and a[3] > b[3]) then
			a, b = b, a
		end
		if mode == "V" then
			c = { kind = "line", lnum = a[2], col = 0, end_lnum = b[2], end_col = 0 }
		else
			-- Charwise (blockwise is treated as charwise). Make the end exclusive
			-- and include the whole last (possibly multibyte) character.
			local line = vim.fn.getline(b[2])
			local last_char = vim.fn.strpart(line, b[3] - 1, 1, true)
			c = { kind = "char", lnum = a[2], col = a[3] - 1, end_lnum = b[2], end_col = math.min(#line, b[3] - 1 + #last_char) }
		end
		vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	elseif not virtual and at_cursor() then
		return M.edit()
	end
	local buf = vim.api.nvim_get_current_buf()
	local title_range = c.lnum == c.end_lnum and ("L" .. c.lnum) or ("L%d-%d"):format(c.lnum, c.end_lnum)
	if virtual then
		-- Comment made on a revision pane: keep the old code for the prompt and
		-- attach the comment to the working file at the mapped line(s).
		if virtual.is_original then
			c.old = { range = title_range, lines = virtual.lines(c.lnum, c.end_lnum) }
			title_range = title_range .. " (old)"
		end
		local a, b = virtual.map(c.lnum), virtual.map(c.end_lnum)
		c.kind, c.col, c.end_col = (a == b and "point" or "line"), 0, 0
		c.lnum, c.end_lnum = math.min(a, b), math.max(a, b)
		buf = vim.fn.bufnr(abs(file))
	end
	input({ title = "Comment · " .. file .. ":" .. title_range }, function(text)
		c.id, c.file, c.text = store.next_id, file, text
		table.insert(store.comments, c)
		store.next_id = store.next_id + 1
		save()
		if buf ~= -1 then
			render(buf)
		end
	end)
end

function M.edit()
	local c = at_cursor()
	if not c then
		return vim.notify("No review comment here", vim.log.levels.WARN)
	end
	input({ title = "Edit comment", default = c.text }, function(text)
		c.text = text
		save()
		rerender(c.file)
	end)
end

function M.delete()
	local c = at_cursor()
	if not c then
		return vim.notify("No review comment here", vim.log.levels.WARN)
	end
	store.comments = vim.tbl_filter(function(x)
		return x.id ~= c.id
	end, store.comments)
	save()
	rerender(c.file)
end

function M.clear()
	load()
	store.comments = {}
	save()
	rerender()
end

local function sorted()
	load()
	sync_all()
	local list = vim.deepcopy(store.comments)
	table.sort(list, function(a, b)
		return a.file == b.file and a.lnum < b.lnum or a.file < b.file
	end)
	return list
end

--- Put all comments in the quickfix list.
function M.list()
	local items = {}
	for _, c in ipairs(sorted()) do
		items[#items + 1] = { filename = abs(c.file), lnum = c.lnum, col = c.col + 1, end_lnum = c.end_lnum, text = c.text:gsub("\n", " ⏎ ") }
	end
	if #items == 0 then
		return vim.notify("No review comments", vim.log.levels.INFO)
	end
	vim.fn.setqflist({}, " ", { title = "Review comments", items = items })
	vim.cmd.copen()
end

--- The commented text as it is right now (buffer if loaded, else the file on
--- disk). Point comments return their whole line.
---@param c review.Comment
---@return string[]
current_text = function(c)
	local path = abs(c.file)
	local buf = vim.fn.bufnr(path)
	local lines
	if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
		lines = vim.api.nvim_buf_get_lines(buf, c.lnum - 1, c.end_lnum, false)
	elseif vim.uv.fs_stat(path) then
		lines = vim.list_slice(vim.fn.readfile(path), c.lnum, c.end_lnum)
	else
		return {}
	end
	if c.kind == "char" and #lines > 0 then
		local n = #lines
		lines[n] = lines[n]:sub(1, c.lnum == c.end_lnum and c.end_col or c.end_col)
		lines[1] = lines[1]:sub(c.col + 1)
	end
	return lines
end

--- All comments as one Markdown block: location, the commented code, the
--- comment.
---@return string?
function M.build()
	local list = sorted()
	if #list == 0 then
		vim.notify("No review comments", vim.log.levels.INFO)
		return
	end
	local out = { M.config.header, "" }
	local function fence(ft, lines)
		out[#out + 1] = "```" .. ft
		vim.list_extend(out, lines)
		out[#out + 1] = "```"
	end
	for i, c in ipairs(list) do
		local loc
		if c.kind == "point" then
			loc = ("%s:%d:%d"):format(c.file, c.lnum, c.col + 1)
		elseif c.lnum == c.end_lnum then
			loc = ("%s:%d"):format(c.file, c.lnum)
		else
			loc = ("%s:%d-%d"):format(c.file, c.lnum, c.end_lnum)
		end
		out[#out + 1] = ("%d. %s"):format(i, loc)
		local ft = vim.filetype.match({ filename = c.file }) or ""
		if c.old and #c.old.lines > 0 then
			out[#out + 1] = ("Comment refers to the previous version (%s), which was:"):format(c.old.range)
			fence(ft, c.old.lines)
			out[#out + 1] = "Current code at the mapped position:"
		end
		local code = current_text(c)
		if #code > 0 then
			fence(ft, code)
		end
		vim.list_extend(out, vim.split(c.text, "\n", { plain = true }))
		out[#out + 1] = ""
	end
	return table.concat(out, "\n")
end

--- Copy all comments to the system clipboard (and the unnamed register).
function M.copy()
	local text = M.build()
	if not text then
		return
	end
	vim.fn.setreg("+", text)
	vim.fn.setreg('"', text)
	vim.notify(("Copied %d review comment(s)"):format(#store.comments))
end

--- After `:CodeDiff` opens from a file buffer, put the cursor in the modified
--- pane on the line we came from. codediff already preselects the current
--- buffer's file (its `focus_file`); this waits for that diff to finish
--- rendering, then moves the cursor. Uses codediff internals, so fail soft.
---@param buf integer source buffer
---@param lnum integer
local function follow_into_review(buf, lnum)
	local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
	local group = vim.api.nvim_create_augroup("review_open", { clear = true })
	local deadline = vim.uv.now() + 10000 -- ignore a CodeDiffOpen from a later, unrelated open
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "CodeDiffOpen",
		once = true,
		callback = function(ev)
			local tab = ev.data and ev.data.tabpage
			if vim.uv.now() > deadline or not tab or (ev.data.mode and ev.data.mode ~= "explorer") then
				return
			end
			local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
			if not ok then
				return
			end
			local tries = 0
			local function poll()
				tries = tries + 1
				local session = lifecycle.get_session(tab)
				local data = session and session.panel and session.panel.data
				if not data or tries > 100 then
					return
				end
				-- Initial selection is scheduled after CodeDiffOpen; `refresh.loading`
				-- clears (scheduled) once the selected diff has rendered.
				local sel = data.current_selection
				if not sel or (session.refresh and session.refresh.loading) or not session.stored_diff_result then
					return vim.defer_fn(function() pcall(poll) end, 30)
				end
				if not data.focus_file or sel.path ~= data.focus_file then
					return vim.notify(("Review: %s has no changes, showing all files"):format(name), vim.log.levels.INFO)
				end
				local _, win = lifecycle.get_windows(tab)
				-- Only when the modified pane is the working file itself (not :0/HEAD).
				if win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
					vim.api.nvim_set_current_win(win)
					pcall(vim.api.nvim_win_set_cursor, win, { math.min(lnum, vim.api.nvim_buf_line_count(buf)), 0 })
					vim.cmd("normal! zz")
				end
			end
			pcall(poll)
		end,
	})
end

--- Review panel: codediff.nvim (staged/unstaged explorer, side-by-side or
--- unified diff, toggle with `t`, close with `q`). Opened from a file buffer,
--- that file is preselected and the cursor lands on the same line.
function M.toggle_mode()
	if vim.fn.exists(":CodeDiff") == 0 then
		return vim.notify("codediff.nvim is not installed (run :Lazy install)", vim.log.levels.ERROR)
	end
	local buf = vim.api.nvim_get_current_buf()
	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	local in_review = ok and lifecycle.get_session(vim.api.nvim_get_current_tabpage()) ~= nil
	if not in_review then
		local stat = vim.bo[buf].buftype == "" and vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
		if stat and stat.type == "file" then
			follow_into_review(buf, vim.api.nvim_win_get_cursor(0)[1])
		else
			pcall(vim.api.nvim_del_augroup_by_name, "review_open")
			vim.notify("Review: current buffer is not a file, showing all changes", vim.log.levels.INFO)
		end
	end
	vim.cmd("CodeDiff")
end

--- Review panel: codediff.nvim. Opened from a file buffer, that file is
--- preselected and the cursor lands on the same line.
function M.open_panel()
	local buf = vim.api.nvim_get_current_buf()
	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	local in_review = ok and lifecycle.get_session(vim.api.nvim_get_current_tabpage()) ~= nil
	if not in_review then
		local stat = vim.bo[buf].buftype == "" and vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
		if stat and stat.type == "file" then
			follow_into_review(buf, vim.api.nvim_win_get_cursor(0)[1])
		else
			pcall(vim.api.nvim_del_augroup_by_name, "review_open")
		end
	end
	vim.cmd("CodeDiff")
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	local group = vim.api.nvim_create_augroup("review_comments", { clear = true })
	local function range_hl()
		vim.api.nvim_set_hl(0, "ReviewCommentRange", { link = "Visual", default = true })
	end
	range_hl()
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = range_hl })
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		group = group,
		callback = function(ev)
			load()
			render(ev.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWritePost", "BufLeave" }, {
		group = group,
		callback = function(ev)
			if store.key and vim.api.nvim_buf_get_name(ev.buf) ~= "" then
				sync_buf(ev.buf)
				save()
			end
		end,
	})

	local subs = { add = M.add, edit = M.edit, delete = M.delete, list = M.list, copy = M.copy, clear = M.clear }
	vim.api.nvim_create_user_command("Review", function(a)
		local fn = subs[a.args ~= "" and a.args or "copy"]
		if not fn then
			return vim.notify("Review: unknown subcommand " .. a.args, vim.log.levels.ERROR)
		end
		fn()
	end, {
		nargs = "?",
		complete = function()
			return vim.tbl_keys(subs)
		end,
		desc = "Review comments: add / edit / delete / list / copy / clear",
	})

	local function map(mode, lhs, fn, desc)
		vim.keymap.set(mode, lhs, fn, { desc = "Review: " .. desc })
	end
	map({ "n", "x" }, "<leader>ma", M.add, "add / edit comment")
	map("n", "<leader>md", M.delete, "delete comment")
	map("n", "<leader>ml", M.list, "list comments (quickfix)")
	map("n", "<leader>my", M.copy, "copy comments to clipboard")
	map("n", "<leader>mc", function()
		if vim.fn.confirm("Clear all review comments?", "&Yes\n&No", 2) == 1 then
			M.clear()
		end
	end, "clear comments")
end

return M
