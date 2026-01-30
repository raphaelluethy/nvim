return {
	{
		dir = "/Users/raphael.luethy@fhnw.ch/Documents/projects/private/cursortab.nvim",
		name = "cursortab.nvim",
		build = "cd server && go build",
		config = function()
			require("cursortab").setup({
				log_level = "trace",
				provider = {
					type = "sweep",
					url = "https://autocomplete.sweep.dev",
					api_key_env = "SWEEP_AI_TOKEN",
				},
			})
		end,
	},
}
