return {
	{
		"kevinhwang91/nvim-ufo",
		event = "BufEnter",
		dependencies = {
			"kevinhwang91/promise-async",
		},
		config = function()
			--- @diagnostic disable: unused-local
			require("ufo").setup({
				provider_selector = function(_bufnr, _filetype, _buftype)
					return { "treesitter", "indent" }
				end,
			})
		vim.o.foldcolumn     = "1"     -- show fold column (optional)
		vim.o.foldenable     = true    -- enable folding
		vim.o.foldlevel      = 99      -- set a high fold-level so folds remain open by default
		vim.o.foldlevelstart = 99      -- make sure on buffer open the fold‐level is high
		end,
	},
}
