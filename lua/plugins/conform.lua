return {
	-- Autoformat
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
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
		-- Oxfmt formats web files through the LSP fallback.
		format_after_save = {
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
			go = { "goimports", "gofumpt" },
			gomod = { "gofmt" },
			gowork = { "gofmt" },
			rust = { "rustfmt", lsp_format = "fallback" },
			java = { "google-java-format", lsp_format = "fallback" },
			kotlin = { "ktfmt", lsp_format = "fallback" },
		},
	},
}
