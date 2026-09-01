return {
	-- Autoformat
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
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
		notify_on_error = false,
		default_format_opts = {
			lsp_format = "fallback",
		},
		format_on_save = {
			timeout_ms = 500,
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
			javascript = { "oxfmt", "biome", stop_after_first = true },
			javascriptreact = { "oxfmt", "biome", stop_after_first = true },
			typescript = { "oxfmt", "biome", stop_after_first = true },
			typescriptreact = { "oxfmt", "biome", stop_after_first = true },
			json = { "oxfmt", "biome", stop_after_first = true },
			jsonc = { "oxfmt", "biome", stop_after_first = true },
			css = { "oxfmt", "biome", stop_after_first = true },
			scss = { "oxfmt", "biome", "prettierd", "prettier", stop_after_first = true },
			html = { "oxfmt", "biome", "prettierd", "prettier", stop_after_first = true },
			markdown = { "oxfmt", "biome", "prettierd", "prettier", stop_after_first = true },
			yaml = { "oxfmt", "biome", stop_after_first = true },
			graphql = { "oxfmt", "biome", stop_after_first = true },
			vue = { "oxfmt", "biome", stop_after_first = true },

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
