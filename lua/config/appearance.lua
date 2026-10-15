-- Follow the system light/dark appearance.
-- Terminals with theme notifications (DEC 2031: Ghostty, kitty, WezTerm, ...)
-- make Nvim update 'background' live. On macOS the system setting is also read
-- at startup and on focus, covering terminals without that support.

local function system_background()
	if vim.fn.has("mac") == 0 then
		return nil
	end
	-- Exits 0 with "Dark" in dark mode; fails when light.
	local result = vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }):wait()
	return (result.code == 0 and result.stdout:match("Dark")) and "dark" or "light"
end

local function sync()
	local bg = system_background()
	if bg and vim.o.background ~= bg then
		vim.o.background = bg
	end
end

sync()

local group = vim.api.nvim_create_augroup("raphaelluethy-appearance", { clear = true })

-- Changing 'background' reloads the colorscheme (monokai-pro-zed picks its variant).
vim.api.nvim_create_autocmd("FocusGained", {
	group = group,
	callback = sync,
})
