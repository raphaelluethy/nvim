return {
	{
		"loctvl842/monokai-pro.nvim",
		lazy = false,
		priority = 1000,
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
		end,
	},
}
