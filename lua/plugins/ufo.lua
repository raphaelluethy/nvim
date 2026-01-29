return {
	{
		"kevinhwang91/nvim-ufo",
		event = "BufEnter",
		dependencies = {
			"kevinhwang91/promise-async",
		},
		keys = {
			{
				"zR",
				function()
					require("ufo").openAllFolds()
				end,
				desc = "Open all folds",
			},
			{
				"zM",
				function()
					require("ufo").closeAllFolds()
				end,
				desc = "Close all folds",
			},
			{
				"zK",
				function()
					require("ufo").peekFoldedLinesUnderCursor()
				end,
				desc = "Peek fold",
			},
			{
				"zr",
				function()
					require("ufo").openFoldsExceptKinds()
				end,
				desc = "Open folds except kinds",
			},
			{
				"zm",
				function()
					require("ufo").closeFoldsWith()
				end,
				desc = "Close folds with level",
			},
			-- Built-in fold commands with descriptions for which-key (matching Zed: z o)
			{ "zo", "zo", desc = "Open fold" },
			{ "zO", "zO", desc = "Open fold recursive" },
			{ "zc", "zc", desc = "Close fold" },
			{ "zC", "zC", desc = "Close fold recursive" },
		},
		config = function()
			--- @diagnostic disable: unused-local
			require("ufo").setup({
				provider_selector = function(_bufnr, _filetype, _buftype)
					return { "treesitter", "indent" }
				end,
			})
			vim.o.foldcolumn = "1" -- show fold column (optional)
			vim.o.foldenable = true -- enable folding
			vim.o.foldlevel = 99 -- set a high fold-level so folds remain open by default
			vim.o.foldlevelstart = 99 -- make sure on buffer open the fold-level is high
		end,
	},
}
