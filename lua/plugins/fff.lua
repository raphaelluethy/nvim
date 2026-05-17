return {
	"dmtrKovalenko/fff.nvim",
	build = function(event)
		if event and event.data and not event.data.active then
			vim.cmd.packadd("fff.nvim")
		end
		require("fff.download").download_or_build_binary()
	end,
	opts = {
		lazy_sync = true,
		max_results = 150,
		max_threads = 4,
		preview = {
			enabled = true,
			max_size = 1024 * 1024,
			chunk_size = 8192,
			binary_file_threshold = 1024,
			wrap_lines = false,
		},
		grep = {
			max_file_size = 1024 * 1024,
			max_matches_per_file = 50,
			smart_case = true,
			time_budget_ms = 120,
			modes = { "plain", "regex", "fuzzy" },
			trim_whitespace = true,
		},
		logging = {
			enabled = false,
		},
	},
	config = function(_, opts)
		require("fff").setup(opts)
	end,
	keys = {
		{
			"<leader>sf",
			function()
				require("fff").find_files()
			end,
			desc = "[S]earch [F]iles (FFF)",
		},
		{
			"<leader>sg",
			function()
				require("fff").live_grep()
			end,
			desc = "[S]earch by [G]rep (FFF)",
		},
		{
			"<leader>sG",
			function()
				require("fff").live_grep({
					grep = {
						modes = { "fuzzy", "plain" },
					},
				})
			end,
			desc = "[S]earch fuzzy [G]rep (FFF)",
		},
		{
			"<leader>sw",
			function()
				require("fff").live_grep({
					query = vim.fn.expand("<cword>"),
				})
			end,
			desc = "[S]earch current [W]ord (FFF)",
		},
	},
}
