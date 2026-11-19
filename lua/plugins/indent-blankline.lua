return {
	"lukas-reineke/indent-blankline.nvim",
	version = "3.*",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },
	keys = {
		{ "<leader>ui", "<cmd>IBLToggle<cr>", desc = "Toggle indent guides" },
	},
	opts = {
		indent = { char = "│" },
		-- Like Zed, draw a thicker active guide without horizontal caps.
		scope = {
			char = "┃",
			highlight = "CursorLineNr",
			show_start = false,
			show_end = false,
		},
	},
}
