-- Always start dark. Setting 'background' from the config pins it, so
-- Neovim's terminal detection (OSC 11) stops overriding it.
vim.o.background = "dark"

vim.api.nvim_create_user_command("ThemeToggle", function()
	vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, { desc = "Toggle between dark and light theme" })

-- User commands must start uppercase; let `:themetoggle` work too.
vim.cmd([[cnoreabbrev <expr> themetoggle getcmdtype() == ':' && getcmdline() ==# 'themetoggle' ? 'ThemeToggle' : 'themetoggle']])
