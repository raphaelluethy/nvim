return {
	-- {
	-- 	dir = "/Users/raphael.luethy@fhnw.ch/Documents/projects/private/cursortab.nvim",
	-- 	name = "cursortab.nvim",
	-- 	build = "cd server && go build",
	-- 	config = function()
	-- 		require("cursortab").setup({
	-- 			log_level = "trace",
	-- 			provider = {
	-- 				type = "sweep",
	-- 				url = "https://autocomplete.sweep.dev",
	-- 				api_key_env = "SWEEP_AI_TOKEN",
	-- 			},
	-- 		})
	-- 	end,
	-- },
	{
		-- dir = "/Users/raphael.luethy@fhnw.ch/Documents/projects/private/blink-edit.nvim",
		-- name = "blink-edit.nvim",
		-- config = function()
		-- 	require("blink-edit").setup({
		-- 		logging = {
		-- 			level = "debug",
		-- 			max_entries = 500,
		-- 		},
		-- 		llm = {
		-- 			backend = "sweep_remote",
		-- 			provider = "sweep", -- Used for stop tokens only
		-- 		},
		-- 	})
		-- end,
	},
}
