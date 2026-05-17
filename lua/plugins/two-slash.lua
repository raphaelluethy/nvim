return {
	{
		"marilari88/twoslash-queries.nvim",
		config = function()
			require("twoslash-queries").setup({
				multi_line = true,
				is_enabled = false,
				highlight = "Comment",
			})
		end,
	},
}
