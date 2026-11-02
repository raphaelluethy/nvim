return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = {
		{
			"<leader>e",
			function()
				local harpoon = require("harpoon")
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end,
			desc = "Harpoon Toggle Menu",
		},
		{
			"<leader>a",
			function()
				require("harpoon"):list():add()
			end,
			desc = "Harpoon add file",
		},
	},
	opts = {
		settings = {
			save_on_toggle = false,
			sync_on_ui_close = false,
			save_on_change = true,
			enter_on_sendcmd = false,
			tmux_autoclose_windows = false,
			excluded_filetypes = { "harpoon", "alpha", "dashboard", "gitcommit" },
			mark_branch = false,
			key = function()
				return vim.uv.cwd()
			end,
		},
	},
}
