return {
	"nvim-mini/mini.extra",
	version = "*",
	cmd = "Pick",
	opts = {},
	dependencies = {
		{
			"nvim-mini/mini.pick",
			version = "*",
			config = function()
				-- Use Mini for LSP pickers without replacing the existing ui-select.
				local select = vim.ui.select
				require("mini.pick").setup()
				vim.ui.select = select
			end,
		},
	},
}
