-- Sidebar rendering for semantic change groups, plus the hunk annotations
-- drawn into codediff's diff buffers. Pure presentation: state lives in
-- sidekick_ext.semantic (init.lua), which also owns the actions.
local M = {}

local ns = vim.api.nvim_create_namespace("sidekick_semantic_panel")
local ns_virt = vim.api.nvim_create_namespace("sidekick_semantic_virt")

local STATUS_HL = {
	M = "CodeDiffStatusModified",
	A = "CodeDiffStatusAdded",
	D = "CodeDiffStatusDeleted",
	R = "CodeDiffStatusRenamed",
	["??"] = "CodeDiffStatusUntracked",
}
local KIND_ICON = {
	feat = "✦",
	fix = "",
	refactor = "",
	test = "",
	docs = "",
	chore = "",
	style = "",
	build = "",
	perf = "",
	new = "",
	other = "",
}

function M.set_highlights()
	local hl = {
		SidekickSemTitle = { link = "Title" },
		SidekickSemKind = { link = "Special" },
		SidekickSemMeta = { link = "NonText" },
		SidekickSemSummary = { link = "Comment" },
		SidekickSemFile = { link = "Normal" },
		SidekickSemDir = { link = "Comment" },
		SidekickSemHunk = { link = "LineNr" },
		SidekickSemNote = { link = "Comment" },
		SidekickSemStatus = { link = "DiagnosticVirtualTextInfo" },
		SidekickSemError = { link = "DiagnosticError" },
		SidekickSemVirtBar = { link = "DiagnosticVirtualTextHint" },
		SidekickSemVirtTitle = { link = "DiagnosticVirtualTextHint" },
		SidekickSemVirtNote = { link = "Comment" },
		SidekickSemWinbar = { link = "WinBar" },
	}
	for name, def in pairs(hl) do
		def.default = true
		vim.api.nvim_set_hl(0, name, def)
	end
end

local function width(s)
	return vim.fn.strdisplaywidth(s)
end

local function truncate(s, max)
	if max <= 0 then
		return ""
	end
	if width(s) <= max then
		return s
	end
	local out = ""
	for ch in vim.gsplit(s, "") do
		if width(out .. ch) > max - 1 then
			break
		end
		out = out .. ch
	end
	return out .. "…"
end

local function wrap(text, max)
	local lines, cur = {}, ""
	for word in text:gmatch("%S+") do
		if cur == "" then
			cur = word
		elseif width(cur .. " " .. word) > max then
			lines[#lines + 1] = cur
			cur = word
		else
			cur = cur .. " " .. word
		end
	end
	if cur ~= "" then
		lines[#lines + 1] = cur
	end
	return lines
end

--- Files of a group in first-appearance order, with their hunks.
---@return { file: string, status: string, hunks: sidekick_ext.sem.Hunk[] }[]
function M.group_files(state, group)
	local files, index = {}, {}
	for _, hash in ipairs(group.hunks) do
		local h = state.by_hash[hash]
		if h then
			local f = index[h.file]
			if not f then
				f = { file = h.file, status = h.status, hunks = {} }
				index[h.file] = f
				files[#files + 1] = f
			end
			f.hunks[#f.hunks + 1] = h
		end
	end
	for _, f in ipairs(files) do
		table.sort(f.hunks, function(a, b)
			return a.new_start < b.new_start
		end)
	end
	return files
end

--- Redraw the panel buffer from state.
---@param state sidekick_ext.sem.State
function M.render(state)
	local buf, win = state.buf, state.win
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local w = (win and vim.api.nvim_win_is_valid(win)) and vim.api.nvim_win_get_width(win) or 46
	local lines, marks, rows = {}, {}, {}

	local function push(segments, row)
		local text, col = "", 0
		for _, seg in ipairs(segments) do
			text = text .. seg[1]
			if seg[2] and #seg[1] > 0 then
				marks[#marks + 1] = { #lines, col, col + #seg[1], seg[2] }
			end
			col = col + #seg[1]
		end
		lines[#lines + 1] = text
		rows[#lines] = row or {}
	end

	if state.status then
		push({ { "  " .. truncate(state.status, w - 3), state.error and "SidekickSemError" or "SidekickSemStatus" } })
		push({ { "" } })
	end
	if #state.groups == 0 and not state.status then
		push({ { "  No local changes.", "SidekickSemMeta" } })
	end

	for gi, g in ipairs(state.groups) do
		local files = M.group_files(state, g)
		local collapsed = state.collapsed[g.id]
		-- Title gets the width; kind is right-aligned only when it fits, the
		-- file count only shows while collapsed.
		local right = collapsed and ("%s · %d"):format(g.kind, #files) or g.kind
		local prefix = (collapsed and "▸ " or "▾ ") .. (KIND_ICON[g.kind] or KIND_ICON.other) .. " "
		local avail = w - width(prefix) - 1
		if width(g.title) + width(right) + 2 > avail then
			right = ""
		end
		local title = truncate(g.title, avail - width(right) - (right ~= "" and 2 or 0))
		local pad = math.max(1, w - width(prefix) - width(title) - width(right) - 1)
		push({ { prefix, "SidekickSemMeta" }, { title, "SidekickSemTitle" }, { string.rep(" ", pad) }, { right, "SidekickSemKind" } }, { kind = "group", group = g })
		if not collapsed then
			if g.summary ~= "" then
				for _, l in ipairs(wrap(g.summary, w - 5)) do
					push({ { "    " .. l, "SidekickSemSummary" } }, { kind = "summary", group = g })
				end
			end
			for _, f in ipairs(files) do
				local name, dir = vim.fs.basename(f.file), vim.fs.dirname(f.file)
				dir = dir ~= "." and (" " .. dir) or ""
				local adds, dels = 0, 0
				for _, h in ipairs(f.hunks) do
					adds, dels = adds + h.adds, dels + h.dels
				end
				local stat = (" +%d -%d"):format(adds, dels)
				local avail = w - 7 - width(name) - width(stat)
				push({
					{ "   " },
					{ (f.status == "??" and "?" or f.status) .. "  ", STATUS_HL[f.status] or "SidekickSemMeta" },
					{ name, "SidekickSemFile" },
					{ truncate(dir, avail), "SidekickSemDir" },
					{ stat, "SidekickSemMeta" },
				}, { kind = "file", group = g, file = f.file, hunk = f.hunks[1] })
				for _, h in ipairs(f.hunks) do
					local loc = ("L%d"):format(h.new_count > 0 and h.new_start or h.old_start)
					local note = g.notes[h.hash] or h.header:match("@@.-@@%s*(.*)$") or ""
					push({
						{ "      ↳ " },
						{ loc, "SidekickSemHunk" },
						{ "  " .. truncate(note, w - 12 - width(loc)), "SidekickSemNote" },
					}, { kind = "hunk", group = g, file = h.file, hunk = h })
				end
			end
		end
		if gi < #state.groups then
			push({ { "" } }, { kind = "blank", group = g })
		end
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, m in ipairs(marks) do
		vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
	end
	state.rows = rows
	if win and vim.api.nvim_win_is_valid(win) then
		local cur = vim.api.nvim_win_get_cursor(win)[1]
		pcall(vim.api.nvim_win_set_cursor, win, { math.min(cur, math.max(1, #lines)), 0 })
		M.winbar(state)
	end
end

function M.winbar(state)
	if not state.win or not vim.api.nvim_win_is_valid(state.win) then
		return
	end
	local model = require("sidekick_ext.semantic.llm").model().label
	local s = (" ✦ Groups · %s "):format(model):gsub("%%", "%%%%")
	vim.wo[state.win].winbar = "%#SidekickSemWinbar#" .. s .. (state.busy and "%#SidekickSemStatus# … " or "")
end

--- The row descriptor under the cursor of the panel window.
function M.row_at_cursor(state)
	if not state.win or not vim.api.nvim_win_is_valid(state.win) then
		return nil
	end
	return state.rows[vim.api.nvim_win_get_cursor(state.win)[1]]
end

--- Move the panel cursor to the next/previous group header.
function M.jump_group(state, dir)
	local cur = vim.api.nvim_win_get_cursor(state.win)[1]
	local i = cur + dir
	while i >= 1 and i <= #state.rows do
		if state.rows[i].kind == "group" then
			return vim.api.nvim_win_set_cursor(state.win, { i, 0 })
		end
		i = i + dir
	end
end

--- Markdown explanation of a group (for the float, clipboard and agents).
---@return string[]
function M.explain_lines(state, group, opts)
	opts = opts or {}
	local out = { ("# %s"):format(group.title), ("_%s_"):format(group.kind), "" }
	if group.summary ~= "" then
		out[#out + 1] = group.summary
		out[#out + 1] = ""
	end
	out[#out + 1] = "## Hunks"
	for _, f in ipairs(M.group_files(state, group)) do
		for _, h in ipairs(f.hunks) do
			local from, to = h.new_start, h.new_start + math.max(h.new_count, 1) - 1
			local loc = h.new_count > 0 and ("%s:L%d-%d"):format(h.file, from, to) or ("%s:L%d (deleted)"):format(h.file, h.old_start)
			local note = group.notes[h.hash]
			out[#out + 1] = ("- %s%s  (+%d -%d)%s"):format(opts.at and "@" or "", loc, h.adds, h.dels, note and ("  " .. note) or "")
		end
	end
	return out
end

function M.show_explain(state, group)
	local lines = M.explain_lines(state, group)
	vim.lsp.util.open_floating_preview(lines, "markdown", {
		border = "rounded",
		focusable = true,
		focus = true,
		wrap = true,
		max_width = math.min(90, vim.o.columns - 4),
		max_height = math.min(30, vim.o.lines - 4),
		title = " " .. group.title .. " ",
		title_pos = "center",
	})
end

---------------------------------------------------------------------------
-- Annotations in codediff's modified buffer

--- Draw "▌ Group · note" above every hunk of `path` in the diff view.
function M.annotate(state, path)
	local cd = require("sidekick_ext.semantic.codediff")
	local _, mbuf = cd.buffers(state.tab)
	if not mbuf or not vim.api.nvim_buf_is_valid(mbuf) then
		return
	end
	local name = vim.api.nvim_buf_get_name(mbuf)
	if name:sub(-#path) ~= path then
		return
	end
	vim.api.nvim_buf_clear_namespace(mbuf, ns_virt, 0, -1)
	local last = vim.api.nvim_buf_line_count(mbuf)
	for _, g in ipairs(state.groups) do
		for _, hash in ipairs(g.hunks) do
			local h = state.by_hash[hash]
			if h and h.file == path then
				local above = h.new_count > 0
				local row = math.max(0, math.min(last - 1, (above and h.new_start or math.max(h.new_start, 1)) - 1))
				local note = g.notes[hash]
				pcall(vim.api.nvim_buf_set_extmark, mbuf, ns_virt, row, 0, {
					virt_lines_above = above,
					virt_lines = {
						{
							{ "▌ ", "SidekickSemVirtBar" },
							{ (KIND_ICON[g.kind] or "") .. " " .. g.title, "SidekickSemVirtTitle" },
							{ note and ("  ·  " .. note) or "", "SidekickSemVirtNote" },
						},
					},
				})
			end
		end
	end
end

function M.clear_annotations(state)
	local cd = require("sidekick_ext.semantic.codediff")
	local _, mbuf = cd.buffers(state.tab)
	if mbuf and vim.api.nvim_buf_is_valid(mbuf) then
		vim.api.nvim_buf_clear_namespace(mbuf, ns_virt, 0, -1)
	end
end

return M
