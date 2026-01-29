return {
	{
		"leonardcser/cursortab.nvim",
		build = "cd server && go build",
		config = function()
			require("cursortab").setup({
				behavior = {
					idle_completion_delay = 150,
					text_change_debounce = 150,
				},
				provider = {
					type = "inline",
					url = "http://localhost:8000",
					max_tokens = 128,
					completion_timeout = 3000,
				},
			})
		end,
	},
}
