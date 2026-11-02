return {
	"stevearc/oil.nvim",
	version = "*",
	dependencies = { "echasnovski/mini.icons" },
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {
		default_file_explorer = false,
		view_options = { show_hidden = true },
	},
	keys = {
		{ "-", "<CMD>Oil<CR>", desc = "Open Oil.nvim" },
	},
}
