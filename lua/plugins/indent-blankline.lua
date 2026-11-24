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
		-- Highlight the active scope without horizontal caps.
		scope = {
			char = "│",
			highlight = "CursorLineNr",
			show_start = false,
			show_end = false,
		},
	},
}
