-- Always start dark. Setting 'background' from the config pins it, so
-- Neovim's terminal detection (OSC 11) stops overriding it.
vim.o.background = "dark"

vim.api.nvim_create_user_command("ThemeToggle", function()
	vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, { desc = "Toggle between dark and light theme" })

-- User commands must start uppercase; let `:themetoggle` work too.
vim.cmd([[cnoreabbrev <expr> themetoggle getcmdtype() == ':' && getcmdline() ==# 'themetoggle' ? 'ThemeToggle' : 'themetoggle']])

-- Light themes often tint diff backgrounds only slightly. In light mode,
-- rebuild the gitsigns and diff groups by mixing the theme's own add / change /
-- delete sign colors into Normal's background (0 = theme bg, 1 = full accent).
-- Set to false to keep the theme's diff colors untouched.
local light_boost = { line = 0.24, inline = 0.42 } ---@type false|{line:number, inline:number}

local function blend(fg, bg, a)
	local function ch(c, shift)
		return bit.band(bit.rshift(c, shift), 0xff)
	end
	local function mix(shift)
		return math.floor(ch(fg, shift) * a + ch(bg, shift) * (1 - a) + 0.5)
	end
	return mix(16) * 0x10000 + mix(8) * 0x100 + mix(0)
end

--- Stronger diff colors for light backgrounds, derived from the active theme.
local function apply_light_boost()
	local b = light_boost
	if not b or vim.o.background ~= "light" then
		return
	end
	local function color(name, key)
		return vim.api.nvim_get_hl(0, { name = name, link = false })[key]
	end
	local bg = color("Normal", "bg")
	if not bg then
		return
	end
	for kind, fallback in pairs({ Add = "DiffAdd", Change = "DiffChange", Delete = "DiffDelete" }) do
		local accent = color("GitSigns" .. kind, "fg") or color(fallback, "fg")
		if accent then
			local line, inline = blend(accent, bg, b.line), blend(accent, bg, b.inline)
			vim.api.nvim_set_hl(0, "GitSigns" .. kind .. "Ln", { bg = line })
			vim.api.nvim_set_hl(0, "GitSigns" .. kind .. "Inline", { bg = inline })
			vim.api.nvim_set_hl(0, "GitSigns" .. kind .. "LnInline", { bg = inline })
		end
	end
	-- Diff mode (review panel): same treatment for the core Diff groups.
	local diff_accents = {
		DiffAdd = color("GitSignsAdd", "fg") or color("Added", "fg"),
		DiffChange = color("GitSignsChange", "fg") or color("Changed", "fg"),
		DiffDelete = color("GitSignsDelete", "fg") or color("Removed", "fg"),
	}
	for group, accent in pairs(diff_accents) do
		if accent then
			vim.api.nvim_set_hl(0, group, { bg = blend(accent, bg, b.line), fg = group == "DiffDelete" and accent or nil })
		end
	end
	if diff_accents.DiffChange then
		vim.api.nvim_set_hl(0, "DiffText", { bg = blend(diff_accents.DiffChange, bg, b.inline) })
	end
	local del = color("GitSignsDelete", "fg")
	if del then
		vim.api.nvim_set_hl(0, "GitSignsDeleteVirtLn", { fg = del, bg = blend(del, bg, b.line) })
		vim.api.nvim_set_hl(0, "GitSignsDeleteVirtLnInline", { bg = blend(del, bg, b.inline) })
	end
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("raphaelluethy-light-boost", { clear = true }),
	callback = apply_light_boost,
})
