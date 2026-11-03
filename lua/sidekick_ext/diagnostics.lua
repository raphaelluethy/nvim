-- Send diagnostics to the active agent session as one prompt.
--
-- What gets sent follows Trouble:
--   - in a Trouble window: the item under the cursor (on a file/group row,
--     everything below it) or the visual selection
--   - elsewhere, with a Trouble view open: everything it lists, with its
--     filters and sort order
--   - no Trouble view: all diagnostics (vim.diagnostic.get())
-- `all = true` skips the cursor/selection rule.
--
-- Sending goes through sidekick_ext.sessions.send_context, so it reaches the
-- active session wherever it runs (Neovim pane / float, or a Rex panel), and
-- with no session starts one the way <leader>cc does.
local M = {}

M.config = {
	header = "Please fix these diagnostics:",
	max_items = 50,
	max_code_lines = 6, -- source lines shown per diagnostic (0 = none)
	submit = false, -- leave the prompt in the agent's input to add instructions
}

---@class sidekick_ext.Diag
---@field filename string absolute path
---@field buf? integer
---@field lnum integer 1-based
---@field col integer 0-based byte column
---@field end_lnum integer 1-based
---@field end_col integer 0-based byte column, exclusive
---@field severity? integer vim.diagnostic.severity
---@field message string
---@field source? string
---@field code? string|integer

---@param it trouble.Item
---@return sidekick_ext.Diag?
local function from_trouble(it)
	local d = it.item or {}
	local message = d.message or d.text or it.text
	if not (it.filename and message) then
		return
	end
	local end_pos = it.end_pos or it.pos
	return {
		filename = it.filename,
		buf = it.buf,
		lnum = it.pos[1],
		col = it.pos[2],
		end_lnum = end_pos[1] or it.pos[1],
		end_col = end_pos[2] or it.pos[2],
		severity = d.severity or it.severity,
		message = message,
		source = d.source,
		code = d.code,
	}
end

---@param d vim.Diagnostic
---@return sidekick_ext.Diag?
local function from_diagnostic(d)
	if not (d.bufnr and vim.api.nvim_buf_is_valid(d.bufnr)) then
		return
	end
	local name = vim.api.nvim_buf_get_name(d.bufnr)
	if name == "" then
		return
	end
	return {
		filename = vim.fs.normalize(name),
		buf = d.bufnr,
		lnum = d.lnum + 1,
		col = d.col,
		end_lnum = (d.end_lnum or d.lnum) + 1,
		end_col = d.end_col or d.col,
		severity = d.severity,
		message = d.message,
		source = d.source,
		code = d.code,
	}
end

--- Trouble view shown in `win`, if any.
---@return trouble.View?
local function trouble_view(win)
	if not package.loaded["trouble"] then
		return
	end
	for _, v in ipairs(require("trouble.view").get({ open = true })) do
		if v.view.win and v.view.win.win == win then
			return v.view
		end
	end
end

--- The Trouble view to read from: the current window's, else the last open
--- diagnostics view, else any open view.
---@return trouble.View?, boolean in_view
local function find_view()
	local cur = trouble_view(vim.api.nvim_get_current_win())
	if cur then
		return cur, true
	end
	if not package.loaded["trouble"] then
		return nil, false
	end
	local views = require("trouble.view").get({ open = true })
	local pick
	for _, v in ipairs(views) do
		if v.mode == "diagnostics" or not pick then
			pick = v.view
		end
	end
	return pick, false
end

---@param view trouble.View
---@param selection boolean
---@return trouble.Item[]
local function view_items(view, selection)
	local ret, seen = {}, {}
	local function add(it)
		if not seen[it] then
			seen[it] = true
			ret[#ret + 1] = it
		end
	end
	if selection then
		for _, node in ipairs(view:selection()) do
			for _, it in ipairs(node:flatten()) do
				add(it)
			end
		end
	else
		for _, section in ipairs(view.sections) do
			for _, it in ipairs(section.items or {}) do
				add(it)
			end
		end
	end
	return ret
end

---@param opts? { all?: boolean }
---@return sidekick_ext.Diag[], string what
function M.collect(opts)
	opts = opts or {}
	local view, in_view = find_view()
	local ret = {} ---@type sidekick_ext.Diag[]
	if view then
		for _, it in ipairs(view_items(view, in_view and not opts.all)) do
			ret[#ret + 1] = from_trouble(it)
		end
		return ret, "Trouble " .. (view.opts.mode or "view")
	end
	for _, d in ipairs(vim.diagnostic.get()) do
		ret[#ret + 1] = from_diagnostic(d)
	end
	table.sort(ret, function(a, b)
		local sa, sb = a.severity or 99, b.severity or 99
		if sa ~= sb then
			return sa < sb
		elseif a.filename ~= b.filename then
			return a.filename < b.filename
		elseif a.lnum ~= b.lnum then
			return a.lnum < b.lnum
		end
		return a.col < b.col
	end)
	return ret, "workspace diagnostics"
end

--- Source lines a diagnostic covers (at most max_code_lines).
---@param d sidekick_ext.Diag
---@return string[]
local function code(d)
	local n = M.config.max_code_lines
	if n <= 0 then
		return {}
	end
	local last = math.min(d.end_lnum, d.lnum + n - 1)
	if d.buf and vim.api.nvim_buf_is_valid(d.buf) and vim.api.nvim_buf_is_loaded(d.buf) then
		return vim.api.nvim_buf_get_lines(d.buf, d.lnum - 1, last, false)
	end
	if vim.fn.filereadable(d.filename) == 1 then
		return vim.list_slice(vim.fn.readfile(d.filename, "", last), d.lnum, last)
	end
	return {}
end

---@param diags sidekick_ext.Diag[]
---@param cwd string paths are shown relative to it
---@return sidekick.Text[]
function M.build(diags, cwd)
	local Loc = require("sidekick.cli.context.location")
	local ret = { { { M.config.header } }, {} } ---@type sidekick.Text[]
	for i, d in ipairs(diags) do
		if i > M.config.max_items then
			ret[#ret + 1] = { { ("… and %d more"):format(#diags - M.config.max_items) } }
			break
		end
		local ctx = { name = d.filename, cwd = cwd }
		-- Location columns are 0-based and inclusive; end_col is exclusive.
		local end_col = math.max(d.col, d.end_col - 1)
		if d.end_lnum > d.lnum or end_col > d.col then
			ctx.range = { from = { d.lnum, d.col }, to = { d.end_lnum, end_col } }
		else
			ctx.row, ctx.col = d.lnum, d.col
		end
		local sev = d.severity and vim.diagnostic.severity[d.severity]
		local line = { { ("%d. "):format(i) } } ---@type sidekick.Text
		if sev then
			local hl = "DiagnosticVirtualText" .. sev:sub(1, 1) .. sev:sub(2):lower()
			vim.list_extend(line, { { "[" .. sev .. "]", hl }, { " " } })
		end
		vim.list_extend(line, Loc.get(ctx, { kind = "position" })[1])
		local tag = {}
		if d.source and d.source ~= "" then
			tag[#tag + 1] = tostring(d.source)
		end
		if d.code and d.code ~= "" then
			tag[#tag + 1] = tostring(d.code)
		end
		if #tag > 0 then
			line[#line + 1] = { " (" .. table.concat(tag, " ") .. ")" }
		end
		ret[#ret + 1] = line
		for _, l in ipairs(vim.split(vim.trim(d.message), "\n", { plain = true })) do
			ret[#ret + 1] = { { "   " .. l } }
		end
		local lines = code(d)
		if #lines > 0 then
			ret[#ret + 1] = { { "   ```" .. (vim.filetype.match({ filename = d.filename }) or "") } }
			for _, l in ipairs(lines) do
				ret[#ret + 1] = { { "   " .. l } }
			end
			ret[#ret + 1] = { { "   ```" } }
		end
		ret[#ret + 1] = {}
	end
	return ret
end

---@param opts? { all?: boolean, submit?: boolean }
function M.send(opts)
	opts = opts or {}
	local diags, what = M.collect(opts)
	if #diags == 0 then
		return vim.notify("No diagnostics to send (" .. what .. ")", vim.log.levels.INFO)
	end
	local Sessions = require("sidekick_ext.sessions")
	local s = Sessions.get_active()
	local text = M.build(diags, s and s.cwd or vim.fn.getcwd())
	local submit = opts.submit
	if submit == nil then
		submit = M.config.submit
	end
	Sessions.send_context({ text = text, submit = submit })
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	vim.api.nvim_create_user_command("SkDiagnostics", function(a)
		M.send({ all = a.args == "all", submit = a.bang or nil })
	end, {
		nargs = "?",
		bang = true,
		complete = function()
			return { "all" }
		end,
		desc = "Send Trouble diagnostics to the active agent session (all = whole view, ! = submit)",
	})
end

return M
