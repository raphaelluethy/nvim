return {
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	opts = {
		integrations = {
			telescope = true,
		},
	},
	keys = {
		{ "<leader>gg", "<CMD>Neogit<CR>", desc = "Open Neogit" },
	},
}
