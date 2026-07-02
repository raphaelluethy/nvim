return {
	"lewis6991/gitsigns.nvim",
	opts = {
		signcolumn = true,
		linehl = false, -- Set true to highlight changed lines.
		word_diff = true, -- Highlight changed text within lines.
	},
	keys = {
		{
			"<leader>hp",
			"<cmd>Gitsigns preview_hunk<cr>",
			desc = "Preview Git hunk in a floating window",
		},
		{
			"]h",
			"<cmd>Gitsigns nav_hunk next<cr>",
			desc = "Next Git hunk",
		},
		{
			"[h",
			"<cmd>Gitsigns nav_hunk prev<cr>",
			desc = "Previous Git hunk",
		},
	},
}
