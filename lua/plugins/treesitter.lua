return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter",
		opts = {},
		config = function()
			local treesitter = require("nvim-treesitter")
			local parsers = {
				"bash",
				"css",
				"diff",
				"go",
				"gomod",
				"gosum",
				"gowork",
				"html",
				"java",
				"javascript",
				"jsdoc",
				"json",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"regex",
				"rust",
				"scss",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"yaml",
			}

			treesitter.setup({})
			vim.treesitter.language.register("json", "jsonc")

			if #vim.api.nvim_list_uis() > 0 then
				treesitter.install(parsers)
			end

			-- Enable treesitter highlighting for future buffers
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
				end,
			})

			-- Enable for current buffer if it has a filetype
			local buf = vim.api.nvim_get_current_buf()
			if vim.bo[buf].filetype ~= "" then
				pcall(vim.treesitter.start, buf)
			end
		end,
	},
}
