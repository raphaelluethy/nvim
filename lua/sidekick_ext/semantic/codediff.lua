-- Thin adapter over codediff.nvim internals (unsupported API). Everything is
-- pcall-guarded and returns nil when codediff changes shape, so the semantic
-- panel degrades to "no diff integration" instead of erroring.
local M = {}

local function lifecycle()
	local ok, m = pcall(require, "codediff.ui.lifecycle")
	return ok and m or nil
end

---@return table? session
function M.session(tab)
	local lc = lifecycle()
	if not lc then
		return nil
	end
	local ok, s = pcall(lc.get_session, tab or vim.api.nvim_get_current_tabpage())
	return ok and s or nil
end

--- The explorer object (session.panel.view) of a codediff tab.
function M.explorer(tab)
	local s = M.session(tab)
	return s and s.panel and s.panel.name == "explorer" and s.panel.view or nil
end

--- Explorer panel data (status_result, current_selection, focus_file, ...).
function M.panel_data(tab)
	local s = M.session(tab)
	return s and s.panel and s.panel.data or nil
end

---@return integer? original_win, integer? modified_win
function M.windows(tab)
	local lc = lifecycle()
	if not lc then
		return nil
	end
	local ok, a, b = pcall(lc.get_windows, tab)
	return ok and a or nil, ok and b or nil
end

---@return integer? original_buf, integer? modified_buf
function M.buffers(tab)
	local lc = lifecycle()
	if not lc then
		return nil
	end
	local ok, a, b = pcall(lc.get_buffers, tab)
	return ok and a or nil, ok and b or nil
end

--- codediff's file entry for a repo-relative path, preferring the unstaged
--- group (its modified side is the working tree, so hunk line numbers match).
---@return table? entry  { path, status, old_path, group }
function M.file_entry(tab, path)
	local data = M.panel_data(tab)
	local status = data and data.status_result
	if not status then
		return nil
	end
	for _, group in ipairs({ "unstaged", "staged" }) do
		for _, e in ipairs(status[group] or {}) do
			if e.path == path then
				local entry = vim.deepcopy(e)
				entry.group, entry.type = group, "file"
				return entry
			end
		end
	end
end

--- Run `:CodeDiff` and call `cb(tab)` once its explorer tab has opened.
---@param cb fun(tab: integer)
function M.open(cb)
	if vim.fn.exists(":CodeDiff") == 0 then
		return vim.notify("codediff.nvim is not installed (run :Lazy install)", vim.log.levels.ERROR)
	end
	local group = vim.api.nvim_create_augroup("sidekick_semantic_open", { clear = true })
	local deadline = vim.uv.now() + 10000
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "CodeDiffOpen",
		once = true,
		callback = function(ev)
			local tab = ev.data and ev.data.tabpage
			if vim.uv.now() > deadline or not tab or (ev.data.mode and ev.data.mode ~= "explorer") then
				return
			end
			vim.schedule(function()
				cb(tab)
			end)
		end,
	})
	vim.cmd("CodeDiff")
end

--- Call `cb()` once the current diff of the tab has finished rendering
--- (initial selection made, refresh idle, diff result stored).
---@param cb fun(ok: boolean)
function M.when_ready(tab, cb)
	local tries = 0
	local function poll()
		tries = tries + 1
		local s = M.session(tab)
		if not s then
			return cb(false)
		end
		if tries > 100 then
			return cb(true)
		end
		local data = s.panel and s.panel.data
		local busy = (s.refresh and s.refresh.loading) or not s.stored_diff_result or (data and not data.current_selection)
		if busy then
			return vim.defer_fn(poll, 30)
		end
		cb(true)
	end
	vim.schedule(poll)
end

--- Select a file in codediff's explorer (shows its diff), then `cb(ok)` once rendered.
---@param entry table file entry from M.file_entry
---@param cb? fun(ok: boolean)
function M.select(tab, entry, cb)
	local ex = M.explorer(tab)
	if not ex or type(ex.on_file_select) ~= "function" then
		if cb then
			cb(false)
		end
		return false
	end
	local ok = pcall(ex.on_file_select, entry, { no_jump = true })
	if not ok then
		if cb then
			cb(false)
		end
		return false
	end
	if cb then
		M.when_ready(tab, cb)
	end
	return true
end

--- Currently selected file (repo-relative path) in the explorer.
function M.current_path(tab)
	local data = M.panel_data(tab)
	local sel = data and data.current_selection
	return sel and sel.path or nil
end

--- Show or hide codediff's own explorer window.
function M.set_explorer_hidden(tab, hidden)
	local ex = M.explorer(tab)
	if not ex or ex.is_hidden == hidden then
		return
	end
	local ok, actions = pcall(require, "codediff.ui.explorer.actions")
	if ok then
		pcall(actions.toggle_visibility, ex)
	end
end

return M
