return {
	"raphaelluethy/magirev-nvim",
	dir = vim.fn.expand("~/Documents/projects/private/magirev-nvim"),
	main = "magirev",
	cmd = "Magirev",
	opts = {},
	keys = {
		{
			"<leader>gm",
			function()
				require("magirev").toggle()
			end,
			desc = "Magirev: review, stage and commit",
		},
	},
}
