-- Follow the macOS system appearance. Neovim 0.12 already detects the
-- terminal background (OSC 11) at startup and terminals like Ghostty, kitty
-- and WezTerm push theme changes live; this covers terminals that do not.
-- Spawning `defaults` costs 5-70 ms on macOS even asynchronously, so the first
-- check runs after the UI is up instead of during startup.
local function sync()
	if vim.fn.has("mac") == 0 then
		return
	end
	vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }, function(result)
		local bg = (result.code == 0 and result.stdout:match("Dark")) and "dark" or "light"
		vim.schedule(function()
			if vim.o.background ~= bg then
				vim.o.background = bg
			end
		end)
	end)
end

local group = vim.api.nvim_create_augroup("raphaelluethy-appearance", { clear = true })
vim.api.nvim_create_autocmd("UIEnter", {
	group = group,
	once = true,
	callback = function()
		vim.schedule(sync)
	end,
})
vim.api.nvim_create_autocmd("FocusGained", {
	group = group,
	callback = sync,
})
