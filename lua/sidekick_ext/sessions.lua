-- Several agent sessions at once, inside Neovim (Zed-style agent panel).
--
-- Every session is a sidekick terminal with its own id (sidekick itself only
-- keeps one session per tool and cwd), so sidekick's terminal handling, file
-- watcher and context sending keep working. One session is "active": it is
-- what <leader>cc toggles and where context (`{this}`, `{file}`, ...) goes.
-- Pane sessions share the right split, so showing one replaces the previous
-- one. Float sessions open in a floating window and can stay open beside a
-- pane session. Sessions die with Neovim (terminal jobs are stopped on exit).
--
-- Windows are panels.nvim panels (lua/sidekick_ext/panels.lua). When the
-- panels group "sidekick" resolves to Rex, new sessions run in Rex instead:
-- a floating layer, a pane beside Neovim, or a tab. Those survive Neovim
-- restarts and are picked up again.
local Agents = require("sidekick_ext.agents")
local SkPanels = require("sidekick_ext.panels")

local M = {}

M.config = {
	working_secs = 3, -- output within this many seconds counts as "working"
}

---@class sidekick_ext.Session
---@field id string sidekick session id
---@field n integer
---@field tool string
---@field title string
---@field prompt? string
---@field sel sidekick_ext.Selection
---@field cwd string
---@field created integer
---@field last_output integer
---@field panel? panels.Panel Rex sessions
---@field layout? "float"|"right"|"tab" Rex sessions

M.sessions = {} ---@type table<string, sidekick_ext.Session>
M.active = nil ---@type string?
local counter = 0

local function title_of(prompt)
	local line = vim.trim((prompt:match("[^\n]*%S[^\n]*") or prompt))
	line = line:gsub("%s+", " ")
	return #line > 48 and (line:sub(1, 47) .. "…") or line
end

---@param s sidekick_ext.Session
---@return sidekick.cli.Terminal?
local PanelTerm = {}
PanelTerm.__index = PanelTerm

--- The Terminal methods sessions use, for a session running in a panel (Rex).
---@param s sidekick_ext.Session
function PanelTerm.new(s)
	return setmetatable({ panel = s.panel, opts = { layout = s.layout }, started = true }, PanelTerm)
end
function PanelTerm:is_running()
	return self.panel:is_valid() and self.panel.exit_code == nil
end
function PanelTerm:is_open()
	return self.panel:is_open()
end
function PanelTerm:show()
	self.panel:show({ focus = false })
end
function PanelTerm:focus()
	self.panel:focus()
end
function PanelTerm:hide()
	self.panel:hide()
end
function PanelTerm:is_focused()
	return false -- Neovim has focus whenever one of our keys runs
end
function PanelTerm:close()
	self.panel:close()
end
function PanelTerm:send(text)
	self.panel:send(text, false)
end
function PanelTerm:submit()
	self.panel:send("", true)
end
function PanelTerm:lines()
	return self.panel:capture()
end

local function term(s)
	if s.panel then
		return s.panel:is_valid() and PanelTerm.new(s) or nil
	end
	return require("sidekick.cli.terminal").get(s.id)
end

local discovered = false

--- Rex sessions from before a restart (or another Neovim): track them again.
local function discover()
	if discovered then
		return
	end
	discovered = true
	if not require("panels.rex").available() then
		return
	end
	for _, p in ipairs(require("panels").discover({ label_prefix = SkPanels.LABEL })) do
		local tool = p.label:sub(#SkPanels.LABEL + 1)
		local id = SkPanels.session_id(p)
		if Agents.specs[tool] and not M.sessions[id] then
			counter = counter + 1
			M.sessions[id] = {
				id = id,
				n = counter,
				tool = tool,
				title = p.title ~= "" and p.title or (Agents.specs[tool].label .. " #" .. counter),
				sel = {},
				cwd = vim.fn.getcwd(),
				created = os.time(),
				last_output = 0,
				panel = p,
				layout = p.layout == "split" and "right" or p.layout,
			}
		end
	end
end

--- Drop sessions whose terminal is gone; keep `active` valid.
local function prune()
	for id, s in pairs(M.sessions) do
		if not term(s) then
			M.sessions[id] = nil
		end
	end
	if M.active and not M.sessions[M.active] then
		M.active = nil
	end
	if not M.active then
		local last = M.list()[#M.list()]
		M.active = last and last.id or nil
	end
end

--- All live sessions, oldest first.
---@return sidekick_ext.Session[]
function M.list()
	discover()
	local ret = {}
	for _, s in pairs(M.sessions) do
		if term(s) then
			ret[#ret + 1] = s
		end
	end
	table.sort(ret, function(a, b)
		return a.n < b.n
	end)
	return ret
end

---@return sidekick_ext.Session?
function M.get_active()
	prune()
	return M.active and M.sessions[M.active] or nil
end

--- Filter for sidekick's cli functions so context goes to the active session.
---@return sidekick.cli.Filter
function M.filter()
	local s = M.get_active()
	return s and { session = s.id } or {}
end

---@param s sidekick_ext.Session
---@return "exited"|"working"|"idle"
function M.status(s)
	local t = term(s)
	if not (t and t:is_running()) then
		return "exited"
	end
	if s.panel then
		return "running"
	end
	return (os.time() - s.last_output) <= M.config.working_secs and "working" or "idle"
end

---@param s sidekick_ext.Session
---@return "float"|"right"|"tab"
function M.layout(s)
	if s.panel then
		return s.layout
	end
	local t = term(s)
	return t and t.opts.layout == "float" and "float" or "right"
end

---@class sidekick_ext.NewSessionOpts
---@field prompt? string
---@field tool? string
---@field sel? sidekick_ext.Selection
---@field layout? "float"|"right"|"tab"
---@field cwd? string
---@field focus? boolean
---@field show? boolean start hidden when false

--- Start a session in Rex (a panels panel).
---@param opts sidekick_ext.NewSessionOpts
---@param tool string
---@param sel sidekick_ext.Selection
local function new_in_rex(opts, tool, sel)
	local c = Agents.command(tool, sel, opts.prompt)
	local layout = opts.layout or "right"
	local panel_layout, position = SkPanels.layout(layout)
	counter = counter + 1
	local title = opts.prompt and title_of(opts.prompt) or (Agents.specs[tool].label .. " #" .. counter)
	local panel = require("panels").open({
		label = SkPanels.LABEL .. tool,
		title = title,
		cmd = c.cmd,
		env = c.env,
		cwd = opts.cwd or vim.fn.getcwd(),
		layout = panel_layout,
		position = position,
		hidden = opts.show == false,
		focus = opts.focus ~= false,
	})
	if not panel then
		return -- panels.nvim reported the error
	end
	---@type sidekick_ext.Session
	local s = {
		id = SkPanels.session_id(panel),
		n = counter,
		tool = tool,
		title = title,
		prompt = opts.prompt,
		sel = sel,
		cwd = opts.cwd or vim.fn.getcwd(),
		created = os.time(),
		last_output = os.time(),
		panel = panel,
		layout = layout,
	}
	M.sessions[s.id] = s
	M.active = s.id
	Agents.set_last_tool(tool)
	return s
end

---@param opts? sidekick_ext.NewSessionOpts
---@return sidekick_ext.Session?
function M.new(opts)
	opts = opts or {}
	local tool = opts.tool or Agents.last_tool()
	if not Agents.specs[tool] then
		vim.notify("sidekick sessions: unknown tool " .. tool, vim.log.levels.ERROR)
		return
	end
	local sel = opts.sel or Agents.selection(tool)
	if opts.layout == "tab" or SkPanels.rex(opts.layout) then
		return new_in_rex(opts, tool, sel)
	end
	local Session = require("sidekick.cli.session")
	local Terminal = require("sidekick.cli.terminal")
	local Config = require("sidekick.config")
	Session.setup()

	local c = Agents.command(tool, sel, opts.prompt)
	counter = counter + 1
	local id = ("terminal: %s#%d"):format(tool, counter)
	local t = Terminal.new({
		tool = Config.get_tool(tool):clone({ cmd = c.cmd, env = c.env }),
		cwd = opts.cwd or vim.fn.getcwd(),
		id = id,
	})
	t.opts.layout = opts.layout or "right"

	---@type sidekick_ext.Session
	local s = {
		id = id,
		n = counter,
		tool = tool,
		title = opts.prompt and title_of(opts.prompt) or (Agents.specs[tool].label .. " #" .. counter),
		prompt = opts.prompt,
		sel = sel,
		cwd = t.cwd,
		created = os.time(),
		last_output = os.time(),
	}
	M.sessions[id] = s
	Agents.set_last_tool(tool)

	if opts.show == false then
		Session.attach(t)
		t:hide()
	else
		M.show(s, { focus = opts.focus })
	end
	if not t:is_running() then
		M.sessions[id] = nil
		prune()
		return
	end
	vim.api.nvim_buf_attach(t.buf, false, {
		on_lines = function()
			s.last_output = os.time()
		end,
	})
	return s
end

--- Show a session in its layout. Pane sessions replace any other pane session.
---@param s sidekick_ext.Session
---@param opts? { focus?: boolean }
function M.show(s, opts)
	opts = opts or {}
	local t = term(s)
	if not t then
		return vim.notify("Session is gone: " .. s.title, vim.log.levels.WARN)
	end
	if t.started and not t:is_running() then
		return vim.notify("Session has exited: " .. s.title, vim.log.levels.WARN)
	end
	if M.layout(s) == "right" then
		-- Pane sessions share the pane.
		for _, other in ipairs(M.list()) do
			if other ~= s and M.layout(other) == "right" then
				local ot = term(other)
				if ot and ot:is_open() then
					ot:hide()
				end
			end
		end
	end
	if not s.panel then
		require("sidekick.cli.session").attach(t)
	end
	t:show()
	if opts.focus ~= false then
		t:focus()
	end
	M.active = s.id
end

---@param s sidekick_ext.Session
function M.hide(s)
	local t = term(s)
	if t then
		t:hide()
	end
end

function M.hide_all()
	for _, s in ipairs(M.list()) do
		M.hide(s)
	end
end

--- Switch a session between the right pane and a floating window.
---@param s sidekick_ext.Session
function M.toggle_float(s)
	local t = term(s)
	if not t then
		return
	end
	if s.panel then
		return vim.notify("Rex sessions keep their layout", vim.log.levels.INFO)
	end
	local open = t:is_open()
	t:hide()
	t.opts.layout = t.opts.layout == "float" and "right" or "float"
	if open then
		M.show(s)
	end
end

---@param s sidekick_ext.Session
function M.kill(s)
	local t = term(s)
	if t then
		t:close()
	end
	M.sessions[s.id] = nil
	prune()
end

--- Send text to a session (shown, not focused) and submit it.
---@param s sidekick_ext.Session
---@param text string
function M.send(s, text)
	local t = term(s)
	if not (t and t:is_running()) then
		return vim.notify("Session is not running: " .. s.title, vim.log.levels.WARN)
	end
	M.show(s, { focus = false })
	t:send(text .. "\n")
	t:submit()
end

--- Toggle the active session's window; with no sessions, open the new-session form.
function M.toggle()
	local s = M.get_active()
	if not s then
		return M.prompt()
	end
	local t = term(s)
	if s.panel then
		-- Rex: keys only reach Neovim while it has focus, so open means hide.
		if s.panel:is_open() then
			s.panel:hide()
		else
			M.show(s)
		end
	elseif t and t:is_open() then
		if t:is_focused() then
			t:hide()
		else
			t:focus()
		end
	else
		M.show(s)
	end
end

--- Toggle the active session; with none, pick an agent and start it in the
--- pane (no prompt). Rex or Neovim per the "agents" switch (lua/plugins/panels.lua).
function M.toggle_or_start()
	if M.get_active() then
		return M.toggle()
	end
	Agents.pick_tool(Agents.last_tool(), function(tool)
		M.new({ tool = tool, layout = "right" })
	end)
end

--- Terminal screen of a session, for telling when its agent has started.
---@param s sidekick_ext.Session
local function screen(s)
	local t = term(s)
	if not t then
		return nil
	end
	if s.panel then
		return table.concat(s.panel:capture(), "\n")
	end
	return t.buf
			and vim.api.nvim_buf_is_valid(t.buf)
			and table.concat(vim.api.nvim_buf_get_lines(t.buf, 0, -1, false), "\n")
		or nil
end

--- Call `cb` once the agent in `s` is up: its screen is non-empty and has not
--- changed for a moment (or after a timeout).
---@param s sidekick_ext.Session
---@param cb fun(s: sidekick_ext.Session)
local function when_ready(s, cb)
	local interval, settle, timeout = 250, 3, 15000
	local last, same, elapsed = nil, 0, 0
	local timer = assert(vim.uv.new_timer())
	timer:start(
		interval,
		interval,
		vim.schedule_wrap(function()
			if timer:is_closing() then
				return
			end
			elapsed = elapsed + interval
			local t = term(s)
			if not (t and t:is_running()) then
				timer:close()
				return vim.notify("Agent session exited before context could be sent", vim.log.levels.WARN)
			end
			local cur = screen(s)
			if cur and vim.trim(cur) ~= "" and cur == last then
				same = same + 1
			else
				same = 0
			end
			last = cur
			if same >= settle or elapsed >= timeout then
				timer:close()
				cb(s)
			end
		end)
	)
end

--- sidekick's send, to the active session. With none, start one the way
--- <leader>cc does (pick an agent, pane, Rex or Neovim per the "agents"
--- switch) and send once it is up. Context is rendered right away, so the
--- selection and cursor are the ones from when the key was pressed.
--- With `focus`, the session (Neovim window or Rex block) gets focus after
--- the send instead of staying in the editor.
---@param opts sidekick.cli.Send
function M.send_context(opts)
	local Cli = require("sidekick.cli")
	local focus = opts.focus == true
	local function deliver(target)
		Cli.send(vim.tbl_extend("force", opts, { filter = { session = target.id }, focus = false }))
		if focus then
			-- Context is rendered; leave visual mode before switching windows.
			require("sidekick.util").exit_visual_mode()
			-- After sidekick's scheduled attach, so it can't take focus back.
			vim.schedule(function()
				if M.sessions[target.id] then
					M.show(target, { focus = true })
				end
			end)
		end
	end
	local s = M.get_active()
	if s then
		return deliver(s)
	end
	if not opts.text then
		local msg, text = Cli.render(opts)
		if msg == "" or not text then
			return vim.notify("Nothing to send.", vim.log.levels.WARN)
		end
		opts = vim.tbl_extend("force", opts, { text = text })
		opts.msg, opts.prompt = nil, nil
	end
	require("sidekick.util").exit_visual_mode()
	Agents.pick_tool(Agents.last_tool(), function(tool)
		local new = M.new({ tool = tool, layout = "right" })
		if new then
			when_ready(new, deliver)
		end
	end)
end

--- Make the next (dir = 1) or previous (dir = -1) session active and show it.
---@param dir 1|-1
function M.cycle(dir)
	local list = M.list()
	if #list == 0 then
		return vim.notify("No agent sessions", vim.log.levels.INFO)
	end
	local idx = 1
	for i, s in ipairs(list) do
		if s.id == M.active then
			idx = i
		end
	end
	local s = list[((idx - 1 + dir) % #list) + 1]
	local t = term(s)
	-- Floats cycle in place; a pane session takes over the pane.
	M.show(s, { focus = t and t:is_focused() })
end

--- Open the prompt form and start a session in the pane or as a float.
--- Also offers Rex background tasks when running inside Rex.
---@param opts? { layout?: "float"|"right", tool?: string }
function M.prompt(opts)
	opts = opts or {}
	local function start(layout)
		return function(text, tool, sel)
			M.new({ prompt = text, tool = tool, sel = sel, layout = layout })
		end
	end
	local actions = {
		{ label = "Start in pane", run = start("right") },
		{ label = "Start as float", run = start("float") },
	}
	if opts.layout == "float" then
		actions[1], actions[2] = actions[2], actions[1]
	end
	if SkPanels.rex("tab") then
		actions[#actions + 1] = { label = "Start in tab", run = start("tab") }
	end
	if require("panels.rex").available() then
		actions[#actions + 1] = {
			label = "Rex hidden",
			run = function(text, tool, sel)
				require("sidekick_ext.tasks").new({ prompt = text, tool = tool, sel = sel, show = false })
			end,
		}
	end
	Agents.form({ title = "New agent session", tool = opts.tool, actions = actions })
end

---@param s sidekick_ext.Session
function M.rename(s, cb)
	vim.ui.input({ prompt = "Session title: ", default = s.title }, function(v)
		if v and vim.trim(v) ~= "" then
			s.title = vim.trim(v)
			if s.panel then
				s.panel:set_title(s.title)
			end
		end
		if cb then
			cb()
		end
	end)
end

--- Telescope picker over sessions. Preview shows the agent's terminal.
function M.pick()
	prune()
	local list = M.list()
	if #list == 0 then
		vim.notify("No agent sessions (<leader>cn starts one)", vim.log.levels.INFO)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local previewers = require("telescope.previewers")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	local function age(s)
		local secs = os.time() - s.created
		return secs < 3600 and ("%dm"):format(secs / 60)
			or secs < 86400 and ("%dh"):format(secs / 3600)
			or ("%dd"):format(secs / 86400)
	end

	local picker
	local function make_finder()
		list = M.list()
		return finders.new_table({
			results = list,
			entry_maker = function(s)
				local t = term(s)
				local where = t and t:is_open() and ({ float = "float", right = "pane", tab = "tab" })[M.layout(s)]
					or "hidden"
				local display = ("%s %-6s %-8s %-9s %-4s %s"):format(
					s.id == M.active and "●" or " ",
					where,
					M.status(s),
					s.tool,
					age(s),
					s.title
				)
				return { value = s, display = display, ordinal = s.tool .. " " .. s.title }
			end,
		})
	end

	local function selected()
		local e = action_state.get_selected_entry()
		return e and e.value
	end

	local function refresh()
		picker:refresh(make_finder(), { reset_prompt = false })
	end

	picker = pickers.new({}, {
		prompt_title = "Agent sessions  (<CR> show · <C-f> float · <C-h> hide · <C-s> send · <C-r> rename · <C-x> kill)",
		finder = make_finder(),
		sorter = conf.generic_sorter({}),
		previewer = previewers.new_buffer_previewer({
			title = "Agent screen",
			define_preview = function(self, entry)
				local s = entry.value
				local t = term(s)
				local lines = {}
				if s.prompt then
					lines = vim.split("Prompt: " .. s.prompt, "\n", { plain = true })
					lines[#lines + 1] = ("─"):rep(60)
				end
				local out = t
					and (t.lines and t:lines() or (t:buf_valid() and vim.api.nvim_buf_get_lines(t.buf, 0, -1, false)))
				if out then
					while #out > 0 and vim.trim(out[#out]) == "" do
						out[#out] = nil
					end
					vim.list_extend(lines, out)
				end
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				vim.schedule(function()
					local win = self.state.winid
					if win and vim.api.nvim_win_is_valid(win) then
						pcall(vim.api.nvim_win_set_cursor, win, { math.max(#lines, 1), 0 })
					end
				end)
			end,
		}),
		attach_mappings = function(bufnr, map)
			actions.select_default:replace(function()
				local s = selected()
				actions.close(bufnr)
				if s then
					M.show(s)
				end
			end)
			map({ "i", "n" }, "<C-f>", function()
				local s = selected()
				actions.close(bufnr)
				if s then
					if M.layout(s) ~= "float" then
						M.toggle_float(s)
					end
					M.show(s)
				end
			end)
			map({ "i", "n" }, "<C-h>", function()
				local s = selected()
				if s then
					M.hide(s)
					refresh()
				end
			end)
			map({ "i", "n" }, "<C-r>", function()
				local s = selected()
				if s then
					M.rename(s, refresh)
				end
			end)
			map({ "i", "n" }, "<C-x>", function()
				local s = selected()
				if s and vim.fn.confirm("Kill session '" .. s.title .. "'?", "&Yes\n&No", 2) == 1 then
					M.kill(s)
					if #M.list() == 0 then
						actions.close(bufnr)
					else
						refresh()
					end
				end
			end)
			map({ "i", "n" }, "<C-s>", function()
				local s = selected()
				actions.close(bufnr)
				if s then
					require("sidekick_ext.input").open({ title = "Send to " .. s.title }, function(text)
						M.send(s, text)
					end)
				end
			end)
			return true
		end,
	})
	picker:find()
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	local group = vim.api.nvim_create_augroup("sidekick_ext_sessions", { clear = true })
	-- The session whose window you enter becomes the active one.
	vim.api.nvim_create_autocmd("WinEnter", {
		group = group,
		callback = function()
			local id = vim.w[vim.api.nvim_get_current_win()].sidekick_session_id
			if id and M.sessions[id] then
				M.active = id
			end
		end,
	})
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "SidekickCliDetach",
		callback = function()
			vim.schedule(prune)
		end,
	})
	vim.api.nvim_create_user_command("SkSession", function(a)
		if a.args ~= "" then
			M.new({ prompt = a.args, layout = a.bang and "float" or "right" })
		else
			M.prompt({ layout = a.bang and "float" or "right" })
		end
	end, { nargs = "*", bang = true, desc = "Start an agent session in the pane (! = float)" })
	vim.api.nvim_create_user_command("SkSessions", M.pick, { desc = "Pick an agent session" })
end

return M
