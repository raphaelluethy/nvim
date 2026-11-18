return {
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-mini/mini.extra", -- also loads mini.pick
	},
	opts = {
		integrations = {
			mini_pick = true,
		},
	},
	keys = {
		{ "<leader>gg", "<CMD>Neogit<CR>", desc = "Open Neogit" },
	},
}
