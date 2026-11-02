return {
	"stevearc/oil.nvim",
	version = "*",
	dependencies = { { "echasnovski/mini.icons", version = "*", opts = {} } },
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {
		view_options = { show_hidden = true },
	},
	keys = {
		{ "-", "<CMD>Oil<CR>", desc = "Open Oil.nvim" },
	},
}
