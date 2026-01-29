return {
	"ThePrimeagen/99",
	event = "VeryLazy",
	config = function()
		local _99 = require("99")

		-- local cwd = vim.uv.cwd()
		-- local basename = vim.fs.basename(cwd)

		_99.setup({
			model = "opencode/kimi-k2.5",
			-- logger = {
			-- 	level = _99.DEBUG,
			-- 	path = "/tmp/" .. basename .. ".99.debug",
			-- 	print_on_error = true,
			-- },
			completion = {
				source = "cmp",
			},
			md_files = {
				"AGENTS.md",
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

		-- Model selector
		vim.keymap.set("n", "<leader>9m", function()
			local models = {
				{ name = "Kimi K2.5", model = "opencode/kimi-k2.5" },
				{ name = "Claude Opus 4.5", model = "opencode/claude-opus-4-5" },
				{ name = "Claude Haiku 4.5", model = "opencode/claude-haiku-4-5" },
				{ name = "GPT 5.2 Codex", model = "opencode/gpt-5.2-codex"}
			}
			vim.ui.select(models, {
				prompt = "Select 99 model:",
				format_item = function(item)
					return item.name
				end,
			}, function(choice)
				if choice then
					_99.set_model(choice.model)
					vim.notify("99 model: " .. choice.name, vim.log.levels.INFO)
				end
			end)
		end, { desc = "Select model" })
	end,
}
