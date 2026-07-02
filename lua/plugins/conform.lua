return {
	-- Autoformat
	"stevearc/conform.nvim",

	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({
					async = true,
					lsp_format = "fallback",
				})
			end,
			mode = { "n" },
			desc = "Format buffer",
		},
		{
			"<leader>cf",
			function()
				require("conform").format({
					async = true,
					lsp_format = "fallback",
				})
			end,
			mode = { "n", "v" },
			desc = "Format buffer/selection",
		},
	},

	opts = {
		default_format_opts = {
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff", "ruff_organize_imports", "ruff_format" },
			go = { "goimports", "gofumpt" },
			gomod = { "gofmt" },
			gowork = { "gofmt" },
			rust = { "rustfmt", lsp_format = "fallback" },
			java = { "google-java-format", lsp_format = "fallback" },
			javascript = { "oxfmt","biome", "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "oxfmt","biome", "prettierd", "prettier", stop_after_first = true },
			typescript = { "oxfmt","biome", "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "oxfmt","biome", "prettierd", "prettier", stop_after_first = true },
			json = { "biome", "prettierd", "prettier", stop_after_first = true },
			jsonc = { "biome", "prettierd", "prettier", stop_after_first = true },
			css = { "biome", "prettierd", "prettier", stop_after_first = true },
			scss = { "prettierd", "prettier", stop_after_first = true },
			html = { "prettierd", "prettier", stop_after_first = true },
			markdown = { "prettierd", "prettier", stop_after_first = true },

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
