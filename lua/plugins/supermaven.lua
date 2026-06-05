return {
	"supermaven-inc/supermaven-nvim",
	enabled = function()
		return #vim.api.nvim_list_uis() > 0
	end,
	config = function()
		require("supermaven-nvim").setup({
			keymaps = {
				accept_suggestion = "<Tab>",
				clear_suggestion = "<C-]>",
				accept_word = "<C-j>",
			},
		})
	end,
}
