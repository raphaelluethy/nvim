-- Panels (local plugin): floats, splits and tabs, in Neovim or, inside Rex, as
-- Rex floating layers / panes / tabs. Loaded at startup: it registers this
-- Neovim for Rex's Ctrl-h/j/k/l pane switching
-- (~/.config/rex/init.lua loads panels.nvim/rex/navigation.lua).

-- Where each feature opens its windows:
--   "rex"  = Rex panes / tabs / floats when Neovim runs inside Rex
--            (outside Rex it falls back to Neovim windows)
--   "nvim" = always Neovim windows and buffers
local use = {
	terminal = "rex", -- <A-t>, <leader>tt, <leader>tv/ts/tT/tf, :Panels term
	agents = "rex", -- <leader>ac, <leader>aN, <leader>aj, <leader>al, <leader>a]/[ (sidekick sessions)
	tasks = "rex", -- <leader>an, <leader>at/aT/aH, :SkTask (background agent tasks)
	markdown = "nvim", -- markvim diagram previews (<CR> on a diagram)
}

local function backend(v)
	assert(v == "rex" or v == "nvim", 'panels: use "rex" or "nvim", got ' .. tostring(v))
	return { backend = v == "rex" and "auto" or "nvim" }
end

return {
	dir = "~/Documents/projects/private/panels.nvim",
	name = "panels.nvim",
	lazy = false,
	opts = {
		-- panels groups are the first ":" segment of a panel's label.
		groups = {
			term = backend(use.terminal),
			sidekick = backend(use.agents),
			["sk-task"] = backend(use.tasks),
			markvim = backend(use.markdown),
		},
	},
}
