-- Zed-style vim mode indicator: a colored pill ("NORMAL", "INSERT", ...) at the
-- right end of Neovim's default statusline. Colors are the vim.* colors from
-- Zed's Monokai Pro V2 themes (Filter Spectrum dark, Filter Sun light).
-- Those themes don't set vim.replace.*, so replace uses the theme's red, the
-- same color as the Zedokai overrides in Zed's settings.json.

local M = {}

local colors = {
	dark = {
		fg = "#222222",
		normal = "#fce566",
		insert = "#7bd88f",
		replace = "#fc618d",
		visual = "#fd9353",
	},
	light = {
		fg = "#f8efe7",
		normal = "#b16803",
		insert = "#218871",
		replace = "#ce4770",
		visual = "#d4572b",
	},
}

-- Keyed by the first character of nvim_get_mode().mode.
local modes = {
	n = { "NORMAL", "Normal" },
	i = { "INSERT", "Insert" },
	R = { "REPLACE", "Replace" },
	v = { "VISUAL", "Visual" },
	V = { "VISUAL LINE", "Visual" },
	["\22"] = { "VISUAL BLOCK", "Visual" },
	s = { "SELECT", "Visual" },
	S = { "SELECT LINE", "Visual" },
	["\19"] = { "SELECT BLOCK", "Visual" },
	c = { "COMMAND", "Normal" },
	t = { "TERMINAL", "Insert" },
}

local function set_highlights()
	local c = colors[vim.o.background] or colors.dark
	for group, key in pairs({ Normal = "normal", Insert = "insert", Replace = "replace", Visual = "visual" }) do
		vim.api.nvim_set_hl(0, "ZedMode" .. group, { fg = c.fg, bg = c[key] })
	end
end

function M.mode()
	local mode = modes[vim.api.nvim_get_mode().mode:sub(1, 1)] or modes.n
	return ("%%#ZedMode%s# %s %%*"):format(mode[2], mode[1])
end

set_highlights()

local group = vim.api.nvim_create_augroup("raphaelluethy-statusline", { clear = true })

-- Colorschemes clear highlights; changing 'background' reloads the colorscheme.
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })
vim.api.nvim_create_autocmd("OptionSet", { group = group, pattern = "background", callback = set_highlights })

vim.api.nvim_create_autocmd("ModeChanged", {
	group = group,
	callback = function()
		vim.cmd.redrawstatus()
	end,
})

-- Keep Nvim's default statusline and append the pill.
local default = vim.api.nvim_get_option_info2("statusline", {}).default
vim.o.statusline = default .. " %{%v:lua.require'config.statusline'.mode()%}"

return M
