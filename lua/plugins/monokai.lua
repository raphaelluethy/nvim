return {
	{
		"loctvl842/monokai-pro.nvim",
		config = function()
			require("monokai-pro").setup({
				transparent_background = false,
				devicons = true,
				filter = "spectrum",
				inc_search = "background", -- underline | background
				background_clear = {
					"nvim-tree",
					"float_win",
					"telescope",
					"toggleterm",
				},
				plugins = {
					bufferline = {
						underline_selected = true,
						underline_visible = false,
						underline_fill = true,
						bold = false,
					},
				},
			})
			vim.cmd("colorscheme monokai-pro")
			-- monokai-pro paints markdown code blocks with a solid black bg,
			-- which clashes with the cleared float bg (background_clear =
			-- "float_win") in LSP hover docs. Drop the bg so hover code blocks
			-- render on the float background.
			vim.api.nvim_set_hl(0, "@markup.raw.block.markdown", {})
			vim.api.nvim_set_hl(0, "@markup.raw.delimiter.markdown", { link = "Comment" })
			-- Float interiors use the near-black suggest-widget bg; match the
			-- editor bg instead so only the border distinguishes floats.
			vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal" })
		end,
	},
}
