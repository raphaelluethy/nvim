return {
	"raphaelluethy/magirev-nvim",
	dir = vim.fn.expand("~/Documents/projects/private/magirev-nvim"),
	main = "magirev",
	cmd = "Magirev",
	opts = {
		provider = { model = "openai/gpt-6.1-terra-fast" },
	},
	keys = {
		{
			"<leader>mg",
			function()
				require("magirev").toggle()
			end,
			desc = "Magirev: review, stage and commit",
		},
		{
			"<leader>mG",
			function()
				require("magirev").regroup()
			end,
			desc = "Magirev: group changes with AI",
		},
	},
}
