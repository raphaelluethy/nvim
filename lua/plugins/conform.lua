local function format()
	-- Conform infers a range in characterwise and linewise Visual mode only.
	if vim.fn.mode() == "\22" then
		vim.notify("Use characterwise or linewise Visual mode to format a selection", vim.log.levels.WARN)
		return
	end
	require("conform").format({ async = true })
end

return {
	-- Autoformat
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	-- <A-f> works in insert mode too; a visual selection formats only that range.
	keys = {
		{ "<A-f>", format, mode = { "n", "i", "x", "s" }, desc = "Format buffer/selection" },
		{ "<leader>f", format, mode = { "n", "x" }, desc = "Format buffer/selection" },
		{ "<leader>cf", format, mode = { "n", "x" }, desc = "Format buffer/selection" },
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
		formatters = {
			stylua = {
				range_args = function(self, ctx)
					-- Conform's Visual range ends at the last included character;
					-- StyLua needs the exclusive byte offset after it.
					local range = vim.deepcopy(ctx.range)
					local last = range["end"]
					local line = vim.api.nvim_buf_get_lines(ctx.buf, last[1] - 1, last[1], true)[1]
					local col = math.max(last[2], 0)
					last[2] = col < #line and col + 1 + vim.str_utf_end(line, col + 1) or #line
					local sty = require("conform.formatters.stylua")
					return sty.range_args(self, vim.tbl_extend("force", ctx, { range = range }))
				end,
			},
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
