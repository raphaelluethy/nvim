return {
	"ThePrimeagen/99",
	event = "VeryLazy",
	config = function()
		local _99 = require("99")

		local cwd = vim.uv.cwd()
		local basename = vim.fs.basename(cwd)

		_99.setup({
			logger = {
				level = _99.DEBUG,
				path = "/tmp/" .. basename .. ".99.debug",
				print_on_error = true,
			},
			completion = {
				source = "cmp",
			},
			md_files = {
				"AGENT.md",
			},
		})

		-- Fill in function body with AI
		vim.keymap.set("n", "<leader>9f", function()
			_99.fill_in_function_prompt()
		end, { desc = "Fill in function" })

		-- Process visual selection with AI
		vim.keymap.set("v", "<leader>9v", function()
			_99.visual_prompt()
		end, { desc = "Visual AI" })

		-- Stop all pending AI requests
		vim.keymap.set({ "n", "v" }, "<leader>9s", function()
			_99.stop_all_requests()
		end, { desc = "Stop all requests" })

		-- View debug logs
		vim.keymap.set("n", "<leader>9l", function()
			_99.view_logs()
		end, { desc = "View logs" })

		-- Navigate request logs
		vim.keymap.set("n", "<leader>9n", function()
			_99.next_request_logs()
		end, { desc = "Next request log" })

		vim.keymap.set("n", "<leader>9p", function()
			_99.prev_request_logs()
		end, { desc = "Prev request log" })
	end,
}
