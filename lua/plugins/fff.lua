return {
	"dmtrKovalenko/fff",
	-- Short commit tags also look like versions to lazy.nvim; pin a release.
	tag = "v0.11.0",
	main = "fff",
	cmd = { "FFFFind", "FFFResume", "FFFScan", "FFFHealth" },
	build = function()
		require("fff.download").download_or_build_binary()
	end,
	opts = {
		lazy_sync = true,
		preview = { max_size = 1024 * 1024 },
		-- Keep live grep regex-first, like ripgrep. Cycle modes with <S-Tab>.
		grep = { modes = { "regex", "plain", "fuzzy" } },
	},
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
	},
}
