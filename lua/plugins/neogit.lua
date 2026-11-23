return {
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"folke/snacks.nvim",
	},
	opts = {
		integrations = {
			snacks = true,
		},
	},
	keys = {
		{ "<leader>gg", "<CMD>Neogit<CR>", desc = "Open Neogit" },
	},
}
