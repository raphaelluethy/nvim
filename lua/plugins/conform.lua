return {
	-- Autoformat
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "ConformInfo" },

	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({
					async = true,
					lsp_fallback = true,
				})
			end,
			mode = { "n" },
			desc = "[F]ormat buffer",
		},
	},

	opts = {
		formatters_by_ft = {
			-- lua = { "stylua" },
			python = { "ruff", "ruff_organize_imports", "ruff_format" },
			javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
			typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },

			-- typst = { "prettypst" },
		},
		-- formatters = {
		--   prettypst = {
		--     args = { "--use-std-in", "--use-std-out" },
		--     stdin = true,
		--   },
		-- },
	},
}
