local function droid_adapter()
	local helpers = require("codecompanion.adapters.acp.helpers")

	return {
		name = "droid",
		formatted_name = "Droid",
		type = "acp",
		roles = {
			llm = "assistant",
			user = "user",
		},
		opts = {
			vision = true,
		},
		commands = {
			default = {
				"droid",
				"exec",
				"--output-format",
				"acp",
			},
		},
		defaults = {
			mcpServers = {},
			timeout = 20000,
		},
		parameters = {
			protocolVersion = 1,
			clientCapabilities = {
				fs = { readTextFile = true, writeTextFile = true },
			},
			clientInfo = {
				name = "CodeCompanion.nvim",
				version = "1.0.0",
			},
		},
		handlers = {
			setup = function()
				return true
			end,
			auth = function()
				return true
			end,
			form_messages = function(self, messages, capabilities)
				return helpers.form_messages(self, messages, capabilities)
			end,
			on_exit = function() end,
		},
	}
end

return {
	"olimorris/codecompanion.nvim",
	version = "^19.0.0",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		interactions = {
			chat = {
				adapter = "claude_code",
			},
			cli = {
				agent = "claude_code",
				agents = {
					claude_code = {
						cmd = "claude",
						args = {},
						description = "Claude Code CLI",
						provider = "terminal",
					},
					cursor_cli = {
						cmd = "agent",
						args = {},
						description = "Cursor Agent CLI",
						provider = "terminal",
					},
					droid = {
						cmd = "droid",
						args = {},
						description = "Factory Droid CLI",
						provider = "terminal",
					},
					opencode = {
						cmd = "opencode",
						args = {},
						description = "OpenCode CLI",
						provider = "terminal",
					},
				},
			},
		},
		adapters = {
			acp = {
				droid = droid_adapter,
				extend = {
					claude_code = {
						defaults = {
							mcpServers = vim.empty_dict(),
						},
					},
					cursor_cli = {
						defaults = {
							mcpServers = vim.empty_dict(),
						},
					},
					opencode = {
						defaults = {
							mcpServers = vim.empty_dict(),
						},
					},
				},
			},
		},
	},
	keys = {
		{ "<leader>cA", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion actions" },
		{ "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "CodeCompanion chat" },
		{ "<leader>cs", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "CodeCompanion add selection" },
		{ "<leader>ci", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "CodeCompanion inline" },
		{ "<leader>cl", "<cmd>CodeCompanionCLI<cr>", mode = "n", desc = "CodeCompanion CLI" },
		{ "<leader>c1", "<cmd>CodeCompanionChat adapter=claude_code<cr>", mode = "n", desc = "Claude Code chat" },
		{ "<leader>c2", "<cmd>CodeCompanionChat adapter=cursor_cli<cr>", mode = "n", desc = "Cursor Agent chat" },
		{ "<leader>c3", "<cmd>CodeCompanionChat adapter=droid<cr>", mode = "n", desc = "Droid chat" },
		{ "<leader>c4", "<cmd>CodeCompanionChat adapter=opencode<cr>", mode = "n", desc = "OpenCode chat" },
	},
}
