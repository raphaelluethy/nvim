return {
	"mfussenegger/nvim-dap",
	cmd = {
		"DapContinue",
		"DapToggleBreakpoint",
		"DapTerminate",
		"DapStepInto",
		"DapStepOver",
		"DapStepOut",
		"DapShowLog",
		"DapInstall",
		"DapUninstall",
	},
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} },
		"jay-babu/mason-nvim-dap.nvim",
		"mfussenegger/nvim-dap-python",
		{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
	},
	keys = {
		{ "<F5>", function() require("dap").continue() end, desc = "Debug: Continue/start" },
		{ "<F10>", function() require("dap").step_over() end, desc = "Debug: Step over" },
		{ "<F11>", function() require("dap").step_into() end, desc = "Debug: Step into" },
		{ "<F12>", function() require("dap").step_out() end, desc = "Debug: Step out" },
		{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle breakpoint" },
		{
			"<leader>dB",
			function()
				vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
					if condition then
						require("dap").set_breakpoint(condition)
					end
				end)
			end,
			desc = "Debug: Conditional breakpoint",
		},
		{ "<leader>dc", function() require("dap").continue() end, desc = "Debug: Continue/start" },
		{ "<leader>di", function() require("dap").step_into() end, desc = "Debug: Step into" },
		{ "<leader>do", function() require("dap").step_over() end, desc = "Debug: Step over" },
		{ "<leader>dO", function() require("dap").step_out() end, desc = "Debug: Step out" },
		{ "<leader>dl", function() require("dap").run_last() end, desc = "Debug: Run last configuration" },
		{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "Debug: Toggle REPL" },
		{ "<leader>dt", function() require("dap").terminate() end, desc = "Debug: Terminate" },
		{ "<leader>du", function() require("dapui").toggle() end, desc = "Debug: Toggle UI" },
		{ "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Debug: Evaluate" },
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		dapui.setup()

		dap.listeners.after.event_initialized.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.disconnect.dapui_config = function()
			dapui.close()
		end

		require("mason-nvim-dap").setup({
			ensure_installed = { "python", "delve", "codelldb" },
			handlers = {
				python = function()
					-- Keep the adapter isolated; dap-python resolves the project's virtualenv.
					require("dap-python").setup("debugpy-adapter")
				end,
			},
		})
	end,
}
