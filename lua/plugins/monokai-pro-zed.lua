-- Monokai Pro Zed: the zed-mp themes as Neovim colorschemes. The repo is
-- private because the themes are licensed; without SSH access to it, lazy.nvim
-- reports the failed clone and Neovim keeps its default colorscheme.
return {
	url = "git@github.com:raphaelluethy/monokai-pro-zed.git",
	name = "monokai-pro-zed",
	lazy = false,
	priority = 1000,
	config = function()
		-- `monokai-pro-zed` follows 'background' (see lua/config/appearance.lua).
		-- Any variant works, e.g. "monokai-pro-filter-spectrum-v3-no-italics".
		require("monokai-pro-zed").setup({
			dark = "monokai-pro-filter-spectrum-v3-no-italics",
			light = "monokai-pro-light-filter-sun-v3-no-italics",
		})
		vim.cmd.colorscheme("monokai-pro-zed")
	end,
}
