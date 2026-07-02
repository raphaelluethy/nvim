return {
	"supermaven-inc/supermaven-nvim",
	config = function()
		if #vim.api.nvim_list_uis() == 0 then
			return
		end

		require("supermaven-nvim").setup({
			keymaps = {
				accept_suggestion = "<Tab>",
				clear_suggestion = "<C-]>",
				accept_word = "<C-j>",
			},
		})
	end,
}
