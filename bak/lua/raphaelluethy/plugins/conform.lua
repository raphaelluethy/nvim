return {
	"stevearc/conform.nvim",
	-- event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			-- Customize or remove this keymap to your liking
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	-- Everything in opts will be passed to setup()
	opts = {
		-- Define your formatters
		formatters_by_ft = {
			lua = { "stylua" },
			-- Conform will run multiple formatters sequentially
			python = { "black" },
			-- python = { "isort", "yapf" },
			-- Use a sub-list to run only the first available formatter
			javascript = { { "prettier" } },
			javascriptreact = { { "prettier" } },
			typescript = { { "prettier" } },
			typescriptreact = { { "prettier" } },
			go = { "goimports", "gofmt" },
			-- Use the "*" filetype to run formatters on all filetypes.
			["*"] = { "codespell" },
			-- Use the "_" filetype to run formatters on filetypes that don't
			-- have other formatters configured.
			["_"] = { "trim_whitespace" },
		},
		-- Set up format-on-save
		format_on_save = { timeout_ms = 500, lsp_fallback = true },
		-- Customize formatters
		formatters = {
			shfmt = {
				prepend_args = { "-i", "2" },
			},
		},
	},
	-- init = function()
	--     -- If you want the formatexpr, here is the place to set it
	--     vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	-- end,
}
-- return {
--     "stevearc/conform.nvim",
--     config = function()
--         require("conform").setup({
--             notify_on_error = false,
--             -- auto formatting
--             format_on_save = {
--                 timeout_ms = 500,
--                 lsp_fallback = true,
--             },
--             formatters_by_ft = {
--                 lua = { "stylua" },
--                 -- Conform will run multiple formatters sequentially
--                 -- python = { "black" },
--                 python = { "isort", "black" },
--                 -- Use a sub-list to run only the first available formatter
--                 javascript = { { "prettier" } },
--                 javascriptreact = { { "prettier" } },
--                 typescript = { { "prettier" } },
--                 typescriptreact = { { "prettier" } },
--                 go = { "goimports", "gofmt" },
--             },
--         })
--         vim.keymap.set({ "n", "v" }, "<leader>f", function()
--             require("conform").format({
--                 lsp_fallback = true,
--                 timeout_ms = 500,
--             })
--         end, {
--             desc = "Format file or range using Conform",
--         })
--     end,
-- }
