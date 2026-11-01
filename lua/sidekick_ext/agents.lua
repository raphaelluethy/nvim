-- Per-agent launch options (model / mode / effort) with dropdown pickers and
-- clickable winbar buttons. Used by hidden tasks and by the main sidekick CLI.
-- Options are passed as CLI flags at launch, so nothing depends on each
-- agent's own slash commands.
local M = {}

local state_file = vim.fn.stdpath("state") .. "/sidekick-agents.json"

---@alias sidekick_ext.OptKey "model"|"mode"|"effort"
---@alias sidekick_ext.Selection { model?: string, mode?: string, effort?: string }

local function lines(cmd)
	local res = vim.system(cmd, { text = true }):wait(5000)
	return res.code == 0 and vim.split(res.stdout, "\n", { trimempty = true }) or {}
end

local function read_json(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local ok, data = pcall(vim.json.decode, f:read("*a"), { luanil = { object = true, array = true } })
	f:close()
	return ok and data or nil
end

local cache = {}
local function cached(key, fn)
	if cache[key] == nil then
		cache[key] = fn()
	end
	return cache[key]
end

---@class sidekick_ext.AgentSpec
---@field label string
---@field options table<sidekick_ext.OptKey, { label: string, list: fun(sel: sidekick_ext.Selection): string[] }>
---@field args fun(sel: sidekick_ext.Selection): string[] flags for the selection
---@field prompt fun(p: string): string[] how to pass an initial prompt
---@field base string[] command without flags
---@field env? fun(sel: sidekick_ext.Selection): table<string, string> environment for the selection

---@type table<string, sidekick_ext.AgentSpec>
M.specs = {
	opencode = {
		label = "opencode",
		base = { "opencode" },
		options = {
			model = {
				label = "Model",
				list = function()
					return cached("opencode.models", function()
						return lines({ "opencode", "models" })
					end)
				end,
			},
			mode = {
				label = "Agent",
				list = function()
					return cached("opencode.agents", function()
						local out = table.concat(lines({ "opencode", "debug", "agents" }), "\n")
						local ok, agents = pcall(vim.json.decode, out)
						local ret = {}
						for _, a in ipairs(ok and agents or {}) do
							if a.mode == "primary" and not a.hidden then
								ret[#ret + 1] = a.id
							end
						end
						return #ret > 0 and ret or { "build", "plan" }
					end)
				end,
			},
			effort = {
				label = "Effort",
				list = function()
					return { "none", "minimal", "low", "medium", "high", "xhigh", "max" }
				end,
			},
		},
		-- The TUI has no --model/--agent flags and normally attaches to a shared
		-- background server. With a selection, run a private server (--standalone)
		-- configured inline. Effort is a model variant: provider/model#variant.
		env = function(sel)
			local env = { OPENCODE_THEME = "system" }
			local cfg = {}
			if sel.model then
				cfg.model = sel.model .. (sel.effort and ("#" .. sel.effort) or "")
			end
			if sel.mode then
				cfg.default_agent = sel.mode
			end
			if next(cfg) then
				env.OPENCODE_CONFIG_CONTENT = vim.json.encode(cfg)
			end
			return env
		end,
		args = function(sel)
			return (sel.model or sel.mode) and { "--standalone" } or {}
		end,
		prompt = function(p)
			return { "--prompt", p }
		end,
	},

	claude = {
		label = "Claude Code",
		base = { "claude" },
		options = {
			model = {
				label = "Model",
				list = function()
					return { "fable", "opus", "sonnet", "haiku", "claude-fable-5-1", "claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-5-5" }
				end,
			},
			mode = {
				label = "Mode",
				list = function()
					return { "manual", "acceptEdits", "auto", "plan", "dontAsk", "bypassPermissions" }
				end,
			},
			effort = {
				label = "Effort",
				list = function()
					return { "low", "medium", "high", "xhigh", "max" }
				end,
			},
		},
		args = function(sel)
			local ret = {}
			if sel.model then
				vim.list_extend(ret, { "--model", sel.model })
			end
			if sel.mode then
				vim.list_extend(ret, { "--permission-mode", sel.mode })
			end
			if sel.effort then
				vim.list_extend(ret, { "--effort", sel.effort })
			end
			return ret
		end,
		prompt = function(p)
			return { p }
		end,
	},

	codex = {
		label = "Codex",
		base = { "codex" },
		options = {
			model = {
				label = "Model",
				list = function()
					return cached("codex.models", function()
						local data = read_json(vim.fn.expand("~/.codex/models_cache.json")) or {}
						local ret = {}
						for _, m in ipairs(data.models or {}) do
							if m.visibility == "list" then
								ret[#ret + 1] = m.slug
							end
						end
						return ret
					end)
				end,
			},
			mode = {
				label = "Sandbox",
				list = function()
					return { "read-only", "workspace-write", "danger-full-access" }
				end,
			},
			effort = {
				label = "Effort",
				list = function(sel)
					local data = cached("codex.cache", function()
						return read_json(vim.fn.expand("~/.codex/models_cache.json")) or {}
					end)
					for _, m in ipairs(data.models or {}) do
						if m.slug == sel.model then
							return vim.tbl_map(function(l)
								return type(l) == "table" and l.effort or l
							end, m.supported_reasoning_levels or {})
						end
					end
					return { "low", "medium", "high", "xhigh", "max" }
				end,
			},
		},
		args = function(sel)
			local ret = {}
			if sel.model then
				vim.list_extend(ret, { "-m", sel.model })
			end
			if sel.mode then
				vim.list_extend(ret, { "-s", sel.mode })
			end
			if sel.effort then
				vim.list_extend(ret, { "-c", ("model_reasoning_effort=%q"):format(sel.effort) })
			end
			return ret
		end,
		prompt = function(p)
			return { p }
		end,
	},

	droid = {
		label = "Droid",
		base = { "droid" },
		options = {
			model = {
				label = "Model",
				list = function()
					return cached("droid.models", function()
						local ret, on = {}, false
						for _, l in ipairs(lines({ "droid", "exec", "--help" })) do
							if l:match("^Available Models:") or l:match("^Custom Models:") then
								on = true
							elseif l:match("^%S") then
								on = false
							elseif on then
								local id = l:match("^%s+(%S+)%s%s+")
								if id then
									ret[#ret + 1] = id
								end
							end
						end
						return ret
					end)
				end,
			},
			mode = {
				label = "Autonomy",
				list = function()
					return { "low", "medium", "high", "spec" }
				end,
			},
			effort = {
				label = "Effort",
				list = function()
					return { "off", "low", "medium", "high", "xhigh", "max" }
				end,
			},
		},
		args = function(sel)
			local ret = {}
			if sel.mode == "spec" then
				ret[#ret + 1] = "--use-spec"
			elseif sel.mode then
				vim.list_extend(ret, { "--auto", sel.mode })
			end
			if sel.model or sel.effort then
				-- Interactive droid has no --model flag; use a per-process settings file.
				local path = vim.fn.stdpath("state") .. "/sidekick-droid-settings.json"
				local f = io.open(path, "w")
				if f then
					f:write(vim.json.encode({
						sessionDefaultSettings = { model = sel.model, reasoningEffort = sel.effort },
					}))
					f:close()
					vim.list_extend(ret, { "--settings", path })
				end
			end
			return ret
		end,
		prompt = function(p)
			return { p }
		end,
	},
}

---------------------------------------------------------------------------
-- Persisted selections
---------------------------------------------------------------------------

---@return { last_tool?: string, tools: table<string, sidekick_ext.Selection> }
local function load()
	local data = read_json(state_file) or {}
	data.tools = data.tools or {}
	return data
end

local function save(data)
	vim.fn.mkdir(vim.fn.fnamemodify(state_file, ":h"), "p")
	local f = io.open(state_file, "w")
	if f then
		f:write(vim.json.encode(data))
		f:close()
	end
end

function M.installed()
	local ret = {}
	for name, spec in pairs(M.specs) do
		if vim.fn.executable(spec.base[#spec.base]) == 1 then
			ret[#ret + 1] = name
		end
	end
	table.sort(ret)
	return ret
end

function M.last_tool()
	local t = load().last_tool
	return (t and M.specs[t]) and t or "opencode"
end

function M.set_last_tool(tool)
	local data = load()
	data.last_tool = tool
	save(data)
end

---@return sidekick_ext.Selection
function M.selection(tool)
	return vim.deepcopy(load().tools[tool] or {})
end

function M.set_selection(tool, sel)
	local data = load()
	data.tools[tool] = sel
	save(data)
end

--- Command and environment for a tool + selection, optionally with a prompt.
---@return { cmd: string[], env: table<string, string> }
function M.command(tool, sel, prompt)
	local spec = M.specs[tool]
	local cmd = vim.deepcopy(spec.base)
	vim.list_extend(cmd, spec.args(sel or {}))
	if prompt then
		vim.list_extend(cmd, spec.prompt(prompt))
	end
	return { cmd = cmd, env = spec.env and spec.env(sel or {}) or {} }
end

--- Full command for a tool + selection as a single argv (env via `env K=V`).
function M.cmd(tool, sel, prompt)
	local c = M.command(tool, sel, prompt)
	local ret = {}
	if next(c.env) then
		ret[1] = "env"
		for k, v in pairs(c.env) do
			ret[#ret + 1] = k .. "=" .. v
		end
	end
	return vim.list_extend(ret, c.cmd)
end

---------------------------------------------------------------------------
-- Pickers
---------------------------------------------------------------------------

--- Dropdown for one option. "default" clears it (agent's own default).
---@param cb fun(value: string|nil)
---@param done? fun() called after the dropdown closes (picked or cancelled)
function M.pick(tool, key, sel, cb, done)
	local opt = M.specs[tool].options[key]
	local items = vim.list_extend({ "default" }, opt.list(sel))
	vim.ui.select(items, {
		prompt = ("%s · %s"):format(M.specs[tool].label, opt.label),
		format_item = function(v)
			return v .. (v == (sel[key] or "default") and "  (current)" or "")
		end,
	}, function(choice)
		if choice then
			cb(choice ~= "default" and choice or nil)
		end
		if done then
			done()
		end
	end)
end

function M.pick_tool(current, cb, done)
	vim.ui.select(M.installed(), {
		prompt = "Agent",
		format_item = function(t)
			return M.specs[t].label .. (t == current and "  (current)" or "")
		end,
	}, function(choice)
		if choice then
			cb(choice)
		end
		if done then
			done()
		end
	end)
end

---------------------------------------------------------------------------
-- Clickable button bar (winbar)
---------------------------------------------------------------------------

M.handlers = {} ---@type table<integer, fun()>

--- Register a click handler and return a clickable %@...@ region. Each bar
--- owns a slot (ids slot*100 + n), so several bars never clobber each other.
function M.button(slot, n, text, fn, hl)
	local id = slot * 100 + n
	M.handlers[id] = fn
	return ("%%%d@v:lua.SidekickExtClick@%%#%s# %s %%*%%X"):format(id, hl or "SidekickExtButton", text)
end

function _G.SidekickExtClick(id)
	local fn = M.handlers[id]
	if fn then
		vim.schedule(fn)
	end
end

--- Bar items for tool + selection. on_change(tool, sel) is called after a pick.
---@param on_change fun(tool: string, sel: sidekick_ext.Selection)
---@param slot integer unique per bar (e.g. the window id)
---@param on_close? fun() called whenever a dropdown closes
function M.bar(tool, sel, on_change, slot, on_close)
	local spec = M.specs[tool]
	local n = 0
	local function button(...)
		n = n + 1
		return M.button(slot, n, ...)
	end
	local parts = {}
	for _, key in ipairs({ "model", "effort" }) do
		local opt = spec.options[key]
		if opt then
			local value = sel[key] or "default"
			if key == "model" then
				local limit = math.max(4, vim.api.nvim_win_get_width(slot) - 50)
				if vim.fn.strdisplaywidth(value) > limit then
					value = vim.fn.strcharpart(value, 0, limit - 1) .. "…"
				end
			end
			if tool == "opencode" and key == "effort" and sel.effort and not sel.model then
				value = value .. " (needs model)"
			end
			parts[#parts + 1] = button(("%s: %s ▾"):format(opt.label, value), function()
				M.pick(tool, key, sel, function(v)
					local new = vim.deepcopy(sel)
					new[key] = v
					if key == "model" and new.effort then
						local levels = spec.options.effort.list(new)
						if not vim.tbl_contains(levels, new.effort) then
							new.effort = nil
						end
					end
					on_change(tool, new)
				end, on_close)
			end)
		end
	end
	return table.concat(parts, " "), n
end

---------------------------------------------------------------------------
-- Prompt form
---------------------------------------------------------------------------

---@class sidekick_ext.FormAction
---@field label string
---@field run fun(text: string, tool: string, sel: sidekick_ext.Selection)

--- Pick an agent, then open the prompt editor with model / effort selectors.
--- Picks are saved per agent. In visual mode the selection (with file/line
--- references) is prefilled as context. The first action is bound to <C-s>.
---@param opts { title?: string, tool?: string, default?: string, actions: sidekick_ext.FormAction[] }
function M.form(opts)
	local default
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		default = require("sidekick.cli").render({ msg = "{selection}" })
		vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	end
	if not opts.tool then
		return M.pick_tool(M.last_tool(), function(tool)
			M.form(vim.tbl_extend("force", opts, { tool = tool, default = default }))
		end)
	end
	default = default or opts.default
	local tool = opts.tool or M.last_tool()
	local sel = M.selection(tool)
	-- The simplified form uses the CLI's own mode default.
	sel.mode = nil
	local actions = {}
	for i, a in ipairs(opts.actions) do
		actions[i] = {
			label = a.label,
			run = function(text)
				a.run(text, tool, sel)
			end,
		}
	end
	local handle
	handle = require("sidekick_ext.input").open({
		title = (opts.title or "New agent session") .. " · " .. M.specs[tool].label,
		default = default,
		actions = actions,
		bar = function(win)
			return M.bar(
				tool,
				sel,
				function(t, new)
					tool, sel = t, new
					M.set_last_tool(t)
					M.set_selection(t, new)
					handle.refresh()
				end,
				win,
				function()
					-- Back to the prompt, ready to type (the picker leaves normal mode).
					vim.schedule(function()
						if vim.api.nvim_win_is_valid(handle.win) then
							vim.api.nvim_set_current_win(handle.win)
							vim.cmd("startinsert!")
						end
					end)
				end
			)
		end,
	})
	return handle
end

local function set_hl()
	vim.api.nvim_set_hl(0, "SidekickExtButton", { link = "TabLine", default = true })
	vim.api.nvim_set_hl(0, "SidekickExtButtonPrimary", { link = "TabLineSel", default = true })
	vim.api.nvim_set_hl(0, "SidekickExtButtonAction", { link = "PmenuSel", default = true })
end

function M.setup()
	set_hl()
	vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
end

return M
