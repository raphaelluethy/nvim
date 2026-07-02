return {
	"raphaelluethy/99",
	config = function()
		local _99 = require("99")
		local pickers = require("99.extensions.telescope")

		_99.setup({
			-- provider = _99.Providers.ClaudeCodeProvider, -- default: OpenCodeProvider
			-- model = "opus",
			provider = _99.Providers.CursorSdkProvider,
			model = "composer-2.5",
			-- model = "openai/gpt-5.5-fast",
			-- tmp_dir = "./tmp",
			completion = {
				source = "native",
			},
			md_files = {
				"AGENTS.md",
			},
		})

		vim.keymap.set("n", "<leader>9s", function()
			_99.search()
		end, { desc = "99 search" })

		vim.keymap.set("n", "<leader>9f", function()
			_99.vibe()
		end, { desc = "99 vibe" })

		vim.keymap.set("v", "<leader>9v", function()
			_99.visual()
		end, { desc = "99 visual" })

		vim.keymap.set({ "n", "v" }, "<leader>9t", function()
			_99.tutorial()
		end, { desc = "99 tutorial" })

		vim.keymap.set({ "n", "v" }, "<leader>9x", function()
			_99.stop_all_requests()
		end, { desc = "99 stop requests" })

		vim.keymap.set("n", "<leader>9o", function()
			_99.open()
		end, { desc = "99 open last result" })

		vim.keymap.set("n", "<leader>9l", function()
			_99.view_logs()
		end, { desc = "99 logs" })

		vim.keymap.set("n", "<leader>9c", function()
			_99.clear_previous_requests()
		end, { desc = "99 clear requests" })

		vim.keymap.set("n", "<leader>9m", function()
			pickers.select_model()
		end, { desc = "99 select model" })

		vim.keymap.set("n", "<leader>9sp", function()
			pickers.select_provider()
		end, { desc = "99 select provider" })
	end,
}
