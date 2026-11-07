return {
	-- Autoformat
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	-- <A-f> works in insert mode too; a visual selection formats only that range.
	keys = {
		{
			"<A-f>",
			function()
				require("conform").format({ async = true })
			end,
			mode = { "n", "i", "x", "s" },
			desc = "Format buffer/selection",
		},
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true })
			end,
			mode = { "n", "x" },
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
