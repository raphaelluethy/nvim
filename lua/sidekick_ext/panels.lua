-- sidekick.nvim on panels.nvim.
--
-- * Neovim sessions keep sidekick's terminal (context, file watching, its
--   keys), but its window is a panels panel: same layouts, sizes and
--   navigation as every other panel.
-- * Rex sessions run the agent in a Rex block (float, pane or tab) and are a
--   sidekick session backend ("panels"), so sidekick's send / {this} / submit
--   reach them like any other session.
-- Which one a new session gets is the panels group config for "sidekick"
-- (lua/plugins/panels.lua).
local Panels = require("panels")

local M = {}

M.LABEL = "sidekick:" -- labels are "sidekick:<tool>"

--- Will new agent sessions run in Rex?
---@param layout? "float"|"right"|"tab"
function M.rex(layout)
	return Panels.resolve({ label = "sidekick:session", layout = M.layout(layout or "right") }).backend == "rex"
end

--- panels layout for a session layout.
---@param layout "float"|"right"|"left"|"top"|"bottom"|"tab"
---@return panels.Layout, panels.Position
function M.layout(layout)
	if layout == "float" or layout == "tab" then
		return layout, "center"
	end
	return "split", layout
end

-- Neovim sessions: sidekick terminal windows as panels ------------------------

local patched = false

local function patch_terminal()
	if patched then
		return
	end
	patched = true
	local Terminal = require("sidekick.cli.terminal")
	local open_win = Terminal.open_win

	---@param self sidekick.cli.Terminal
	function Terminal:open_win()
		if self:is_open() or not self.buf then
			return
		end
		local layout, position = M.layout(self.opts.layout)
		local win_opts = layout == "float" and self.opts.float or self.opts.split
		local size = {
			width = (win_opts.width or 0) > 0 and win_opts.width or nil,
			height = (win_opts.height or 0) > 0 and win_opts.height or nil,
		}
		local id = "sidekick:" .. self.id
		local existing = Panels.get(id)
		if existing and existing.layout ~= layout then
			existing:close() -- moved between float and pane: open it anew
		end
		local panel = Panels.open({
			id = id,
			label = "sidekick:terminal",
			title = self.tool.name,
			buf = self.buf,
			backend = "nvim",
			layout = layout,
			position = position,
			size = size,
			focus = false,
		})
		if not panel then
			return open_win(self)
		end
		self.panel = panel
		self.win = panel.win
		vim.w[self.win].sidekick_cli = self.tool
		vim.w[self.win].sidekick_session_id = self.id
		self:wo()
	end
end

-- Rex sessions: a sidekick session backend ----------------------------------

---@class sidekick_ext.PanelSession: sidekick.cli.Session
---@field panel panels.Panel
local Backend = {}
Backend.__index = Backend
Backend.priority = 20
Backend.external = true

function Backend:init()
	self.external = true
end

-- Sessions are started by sidekick_ext.sessions (it knows the layout), so
-- sidekick never starts or attaches anything itself.
function Backend:start() end
function Backend:attach() end

function Backend:is_running()
	return self.panel ~= nil and self.panel:is_valid() and self.panel.exit_code == nil
end

function Backend:send(text)
	self.panel:send(text, false)
end

function Backend:submit()
	self.panel:send("", true)
end

---@return sidekick.cli.session.State[]
function Backend.sessions()
	local seen, ret = {}, {}
	local function add(p)
		if not seen[p.id] and p.label and vim.startswith(p.label, M.LABEL) and p.backend ~= "nvim" then
			seen[p.id] = true
			ret[#ret + 1] = {
				id = M.session_id(p),
				cwd = vim.fn.getcwd(),
				tool = p.label:sub(#M.LABEL + 1),
				panel = p,
				mux_session = p.id,
			}
		end
	end
	for _, p in ipairs(Panels.list({ label_prefix = M.LABEL })) do
		add(p)
	end
	for _, p in ipairs(Panels.discover({ label_prefix = M.LABEL })) do
		add(p)
	end
	return vim.tbl_filter(function(s)
		return require("sidekick.config").get_tool(s.tool) ~= nil
	end, ret)
end

--- sidekick session id of a panel-backed session.
---@param p panels.Panel
function M.session_id(p)
	return "panels: " .. p.id
end

function M.setup()
	patch_terminal()
	local Session = require("sidekick.cli.session")
	Session.setup()
	Session.register("panels", Backend)
end

return M
