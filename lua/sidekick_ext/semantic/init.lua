-- Semantic change groups for the codediff review panel: a cheap model groups
-- the local diff into changelists with explanations (like JetBrains' AI
-- change grouping). The sidebar replaces codediff's file explorer; selecting a
-- group/file/hunk shows it in codediff, and every hunk in the diff gets a
-- "▌ Group · note" line.
local M = {}

local Hunks = require("sidekick_ext.semantic.hunks")
local Llm = require("sidekick_ext.semantic.llm")
local Panel = require("sidekick_ext.semantic.panel")
local Cd = require("sidekick_ext.semantic.codediff")

M.config = {
	width = 46,
	auto_refresh = true, -- after :w in the repo: re-collect, model assigns only the new hunks
	debounce = 2000,
}

---@class sidekick_ext.sem.State
---@field tab integer codediff tabpage
---@field root string
---@field hunks sidekick_ext.sem.Hunk[]
---@field by_hash table<string, sidekick_ext.sem.Hunk>
---@field groups sidekick_ext.sem.Group[]
---@field set_hash? string
---@field win? integer
---@field buf? integer
---@field rows table[]
---@field collapsed table<integer, boolean>
---@field status? string
---@field error? boolean
---@field busy? boolean
---@field generation integer
---@field proc? vim.SystemObj

---@type table<integer, sidekick_ext.sem.State>
local states = {}

local function new_state(tab, root)
	return { tab = tab, root = root, hunks = {}, by_hash = {}, groups = {}, rows = {}, collapsed = {}, generation = 0 }
end

local function set_status(state, msg, is_error)
	state.status, state.error = msg, is_error
	Panel.render(state)
end

local function index(state, hunks)
	state.hunks, state.by_hash = hunks, {}
	for _, h in ipairs(hunks) do
		state.by_hash[h.hash] = h
	end
	state.set_hash = Hunks.set_hash(hunks)
end

--- Keep existing group membership (by hunk hash); groups whose hunks all
--- vanished are dropped. Returns the merged groups and the hunks that are not
--- in any group yet.
---@return sidekick_ext.sem.Group[], sidekick_ext.sem.Hunk[]
local function merge_groups(state, groups)
	local used, out = {}, {}
	for _, g in ipairs(groups) do
		local keep = {}
		for _, hash in ipairs(g.hunks) do
			if state.by_hash[hash] and not used[hash] then
				keep[#keep + 1] = hash
				used[hash] = true
			end
		end
		if #keep > 0 then
			g.hunks = keep
			out[#out + 1] = g
		end
	end
	local fresh = {}
	for _, h in ipairs(state.hunks) do
		if not used[h.hash] then
			fresh[#fresh + 1] = h
		end
	end
	for i, g in ipairs(out) do
		g.id = i
	end
	return out, fresh
end

local function annotate_current(state)
	local path = Cd.current_path(state.tab)
	if path then
		Cd.when_ready(state.tab, function()
			Panel.annotate(state, path)
		end)
	end
end

--- Collect hunks, then group them: cache hit → done; existing groups → only
--- the new hunks go to the model ("assign"); otherwise a full grouping.
--- `force` ignores the cache and existing groups.
---@param state sidekick_ext.sem.State
---@param opts? { force?: boolean }
function M.load(state, opts)
	opts = opts or {}
	state.generation = state.generation + 1
	local gen = state.generation
	state.busy = true
	if state.proc then
		pcall(state.proc.kill, state.proc, 15)
		state.proc = nil
	end
	set_status(state, "Collecting changes…")
	Hunks.collect(state.root, function(err, hunks)
		if gen ~= state.generation then
			return
		end
		if err then
			state.busy = false
			return set_status(state, "git: " .. err, true)
		end
		index(state, hunks)
		local set_hash = state.set_hash
		local function finish(groups)
			if gen ~= state.generation then
				return
			end
			state.proc, state.busy, state.groups = nil, false, groups
			Llm.cache_put(state.root, set_hash, groups)
			set_status(state, nil)
			annotate_current(state)
		end
		local function fail(lerr, fallback)
			if gen ~= state.generation then
				return
			end
			state.proc, state.busy, state.groups = nil, false, fallback
			set_status(state, lerr, true)
		end
		if #hunks == 0 then
			return finish({})
		end
		local cached = not opts.force and Llm.cache_get(state.root, set_hash)
		if cached then
			return finish((merge_groups(state, cached)))
		end
		-- Start from the groups we have, or the last grouping of this repo.
		local base = opts.force and {} or (#state.groups > 0 and state.groups or Llm.latest_get(state.root) or {})
		local groups, fresh = merge_groups(state, base)
		if #fresh == 0 then
			return finish(groups)
		end
		if #groups > 0 then
			-- Show the re-mapped groups while the model assigns the new hunks.
			state.groups = groups
			set_status(state, ("Assigning %d new %s with %s…"):format(#fresh, #fresh == 1 and "hunk" or "hunks", Llm.model().label))
			state.proc = Llm.assign(fresh, groups, state.root, function(lerr, merged)
				if lerr then
					-- Keep the diff reviewable: unassigned hunks become their own group.
					local hashes = {}
					for _, h in ipairs(fresh) do
						hashes[#hashes + 1] = h.hash
					end
					groups[#groups + 1] = { id = #groups + 1, title = "New changes", kind = "new", summary = "Model call failed; press r to regroup.", hunks = hashes, notes = {} }
					return fail(lerr, groups)
				end
				finish(merged)
			end)
			return
		end
		set_status(state, ("Grouping %d hunks with %s…"):format(#hunks, Llm.model().label))
		state.proc = Llm.group(hunks, state.root, function(lerr, result)
			if lerr then
				return fail(lerr, {})
			end
			finish(result)
		end)
	end)
end

function M.refresh(state)
	M.load(state)
end

function M.regroup(state)
	M.load(state, { force = true })
end

---------------------------------------------------------------------------
-- Opening things in codediff

--- Show a hunk's file in codediff and put the cursor on the hunk.
function M.open_hunk(state, hunk, focus)
	local entry = Cd.file_entry(state.tab, hunk.file)
	if not entry then
		return vim.notify(("Semantic: %s is not in the review (refresh with R)"):format(hunk.file), vim.log.levels.WARN)
	end
	Cd.select(state.tab, entry, function(ok)
		if not ok then
			return
		end
		local owin, mwin = Cd.windows(state.tab)
		local win, line = mwin, hunk.new_start
		if hunk.new_count == 0 and owin and vim.api.nvim_win_is_valid(owin) then
			win, line = owin, hunk.old_start
		end
		if win and vim.api.nvim_win_is_valid(win) then
			local last = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win))
			pcall(vim.api.nvim_win_set_cursor, win, { math.max(1, math.min(line, last)), 0 })
			vim.api.nvim_win_call(win, function()
				vim.cmd("normal! zz")
			end)
			if focus then
				vim.api.nvim_set_current_win(win)
			end
		end
		Panel.annotate(state, hunk.file)
	end)
end

local function send_group(state, group)
	local lines = Panel.explain_lines(state, group, { at = true })
	table.insert(lines, 1, "Context: this semantic change group from my local diff.")
	table.insert(lines, 2, "")
	local text = {}
	for _, l in ipairs(lines) do
		text[#text + 1] = { { l } }
	end
	local ok = pcall(function()
		require("sidekick.cli").send({ text = text, submit = false })
	end)
	if not ok then
		vim.fn.setreg("+", table.concat(lines, "\n"))
		vim.notify("No sidekick CLI attached; copied to clipboard")
	end
end

---------------------------------------------------------------------------
-- Window

local function keymaps(state)
	local function map(lhs, fn, desc)
		vim.keymap.set("n", lhs, fn, { buffer = state.buf, nowait = true, desc = "Semantic: " .. desc })
	end
	local function row()
		return Panel.row_at_cursor(state) or {}
	end
	local function toggle_group(g)
		if g then
			state.collapsed[g.id] = not state.collapsed[g.id] or nil
			Panel.render(state)
		end
	end
	local function open(focus)
		local r = row()
		if r.kind == "group" or r.kind == "summary" or r.kind == "blank" then
			return toggle_group(r.group)
		elseif r.hunk then
			M.open_hunk(state, r.hunk, focus)
		end
	end
	map("<CR>", function()
		open(false)
	end, "open")
	map("o", function()
		open(true)
	end, "open and focus diff")
	map("<2-LeftMouse>", function()
		open(false)
	end, "open")
	map("K", function()
		local r = row()
		if r.group then
			Panel.show_explain(state, r.group)
		end
	end, "explain group")
	map("za", function()
		toggle_group(row().group)
	end, "fold group")
	map("<Tab>", function()
		toggle_group(row().group)
	end, "fold group")
	map("zM", function()
		for _, g in ipairs(state.groups) do
			state.collapsed[g.id] = true
		end
		Panel.render(state)
	end, "fold all")
	map("zR", function()
		state.collapsed = {}
		Panel.render(state)
	end, "unfold all")
	map("]]", function()
		Panel.jump_group(state, 1)
	end, "next group")
	map("[[", function()
		Panel.jump_group(state, -1)
	end, "previous group")
	map("r", function()
		M.regroup(state)
	end, "regroup with model")
	map("R", function()
		M.refresh(state)
	end, "refresh hunks")
	map("m", function()
		local model = Llm.cycle_model()
		Panel.winbar(state)
		vim.notify("Semantic: model " .. model.label .. " (r to regroup)")
	end, "cycle model")
	map("s", function()
		local r = row()
		if r.group then
			send_group(state, r.group)
		end
	end, "send group to sidekick CLI")
	map("y", function()
		local r = row()
		if r.group then
			vim.fn.setreg("+", table.concat(Panel.explain_lines(state, r.group), "\n"))
			vim.notify("Semantic: explanation copied")
		end
	end, "yank explanation")
	map("t", function()
		M.close(state.tab)
	end, "back to file explorer")
	map("q", function()
		M.close(state.tab)
	end, "close")
	map("?", function()
		vim.notify(table.concat({
			"<CR> open  o open+focus  K explain  <Tab>/za fold  zM/zR fold all",
			"]] [[ groups  r regroup  R refresh  m model  s send  y yank  t/q close",
		}, "\n"))
	end, "help")
end

local function create_window(state)
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		return
	end
	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		state.buf = vim.api.nvim_create_buf(false, true)
		vim.bo[state.buf].buftype = "nofile"
		vim.bo[state.buf].bufhidden = "hide"
		vim.bo[state.buf].swapfile = false
		vim.bo[state.buf].filetype = "sidekick-semantic"
		vim.bo[state.buf].modifiable = false
		pcall(vim.api.nvim_buf_set_name, state.buf, "Semantic groups [" .. state.tab .. "]")
		keymaps(state)
	end
	vim.api.nvim_set_current_tabpage(state.tab)
	vim.cmd(("topleft %dvsplit"):format(M.config.width))
	state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.win, state.buf)
	local wo = vim.wo[state.win]
	wo.number, wo.relativenumber, wo.cursorline, wo.wrap = false, false, true, false
	wo.signcolumn, wo.foldcolumn, wo.statuscolumn, wo.list, wo.spell = "no", "0", "", false, false
	wo.winfixwidth = true
	Panel.winbar(state)
end

--- Open the panel in a codediff tab.
function M.open(tab)
	tab = tab or vim.api.nvim_get_current_tabpage()
	local session = Cd.session(tab)
	if not session then
		return vim.notify("Semantic: not a codediff tab", vim.log.levels.WARN)
	end
	local root = session.git_root or vim.fs.root(0, ".git") or vim.fn.getcwd()
	local state = states[tab]
	if not state then
		state = new_state(tab, root)
		states[tab] = state
	end
	Cd.set_explorer_hidden(tab, true)
	vim.schedule(function()
		create_window(state)
		Panel.render(state)
		if #state.groups == 0 and not state.busy then
			M.load(state)
		else
			annotate_current(state)
		end
	end)
end

function M.close(tab)
	local state = states[tab or vim.api.nvim_get_current_tabpage()]
	if not state then
		return
	end
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		-- Avoid closing the last window of the tab.
		if #vim.api.nvim_tabpage_list_wins(state.tab) > 1 then
			vim.api.nvim_win_close(state.win, true)
		end
	end
	state.win = nil
	Panel.clear_annotations(state)
	Cd.set_explorer_hidden(state.tab, false)
end

--- Open the panel (opening codediff first when needed) or close it.
function M.toggle()
	local tab = vim.api.nvim_get_current_tabpage()
	if Cd.session(tab) then
		local state = states[tab]
		if state and state.win and vim.api.nvim_win_is_valid(state.win) then
			return M.close(tab)
		end
		return M.open(tab)
	end
	Cd.open(function(t)
		M.open(t)
	end)
end

---@return sidekick_ext.sem.State?
function M.state(tab)
	return states[tab or vim.api.nvim_get_current_tabpage()]
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	if opts and opts.llm then
		Llm.config = vim.tbl_deep_extend("force", Llm.config, opts.llm)
	end
	Panel.set_highlights()
	local group = vim.api.nvim_create_augroup("sidekick_semantic", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = Panel.set_highlights })

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "CodeDiffFileSelect",
		callback = function(ev)
			local state = ev.data and states[ev.data.tabpage]
			if state and state.win and vim.api.nvim_win_is_valid(state.win) and ev.data.path then
				Cd.when_ready(state.tab, function()
					Panel.annotate(state, ev.data.path)
				end)
			end
		end,
	})
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "CodeDiffClose",
		callback = function(ev)
			local tab = ev.data and ev.data.tabpage
			local state = tab and states[tab]
			if state then
				if state.proc then
					pcall(state.proc.kill, state.proc, 15)
				end
				states[tab] = nil
				if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
					vim.api.nvim_buf_delete(state.buf, { force = true })
				end
			end
		end,
	})

	local timer
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		callback = function(ev)
			if not M.config.auto_refresh then
				return
			end
			local name = vim.api.nvim_buf_get_name(ev.buf)
			for _, state in pairs(states) do
				if state.win and vim.api.nvim_win_is_valid(state.win) and vim.fs.relpath(state.root, name) then
					if timer then
						timer:stop()
					end
					timer = vim.defer_fn(function()
						if not state.busy then
							M.refresh(state)
						end
					end, M.config.debounce)
					return
				end
			end
		end,
	})

	vim.api.nvim_create_user_command("SkSemantic", function(a)
		local sub = a.args ~= "" and a.args or "toggle"
		local state = M.state()
		if sub == "toggle" then
			M.toggle()
		elseif sub == "open" then
			M.open()
		elseif sub == "close" then
			M.close()
		elseif sub == "regroup" and state then
			M.regroup(state)
		elseif sub == "refresh" and state then
			M.refresh(state)
		elseif sub == "model" then
			vim.notify("Semantic: model " .. Llm.cycle_model().label)
			if state then
				Panel.winbar(state)
			end
		end
	end, {
		nargs = "?",
		complete = function()
			return { "toggle", "open", "close", "regroup", "refresh", "model" }
		end,
		desc = "Semantic change groups",
	})
end

return M
