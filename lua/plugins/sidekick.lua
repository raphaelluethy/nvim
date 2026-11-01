return {
	"folke/sidekick.nvim",
	version = "*",
	-- Loaded at startup: next edit suggestions (NES) attach to the Copilot LSP.
	lazy = false,
	opts = {
		cli = {
			picker = "telescope",
			tools = {
				opencode = { cmd = { "opencode" } },
				droid = { cmd = { "droid" } },
			},
		},
	},
	config = function(_, opts)
		require("sidekick").setup(opts)
		require("sidekick_ext.agents").setup()
		require("sidekick_ext.tasks").setup()
		require("sidekick_ext.review").setup()

		-- Copilot ghost text via Neovim's native inline completion.
		-- <Tab> accepts (see blink.lua); <M-]> / <M-[> cycle alternatives.
		vim.lsp.inline_completion.enable(true)
		vim.keymap.set("i", "<M-]>", function()
			vim.lsp.inline_completion.select({ count = 1 })
		end, { desc = "Next Copilot suggestion" })
		vim.keymap.set("i", "<M-[>", function()
			vim.lsp.inline_completion.select({ count = -1 })
		end, { desc = "Previous Copilot suggestion" })

		vim.keymap.set("n", "<leader>ta", function()
			local enable = not vim.lsp.inline_completion.is_enabled()
			vim.lsp.inline_completion.enable(enable)
			require("sidekick.nes").enable(enable)
			vim.notify("Copilot " .. (enable and "enabled" or "disabled"))
		end, { desc = "Toggle AI inline completion" })
	end,
	keys = {
		{
			"<Tab>",
			function()
				-- Jump to the next edit suggestion, or apply it when already there.
				if not require("sidekick").nes_jump_or_apply() then
					return "<Tab>"
				end
			end,
			expr = true,
			desc = "Goto/Apply next edit suggestion",
		},
		{
			"<leader>cc",
			function()
				require("sidekick.cli").toggle({ filter = { installed = true } })
			end,
			desc = "Sidekick: Toggle CLI",
		},
		{
			"<leader>cl",
			function()
				require("sidekick.cli").select({ filter = { installed = true } })
			end,
			desc = "Sidekick: Select CLI",
		},
		{
			"<leader>cA",
			function()
				require("sidekick.cli").prompt()
			end,
			mode = { "n", "v" },
			desc = "Sidekick: Select prompt",
		},
		{
			"<leader>ci",
			function()
				require("sidekick.cli").send({ msg = "{this}" })
			end,
			mode = { "n", "v" },
			desc = "Sidekick: Send cursor context",
		},
		{
			"<leader>cs",
			function()
				require("sidekick.cli").send({ msg = "{selection}" })
			end,
			mode = "v",
			desc = "Sidekick: Send selection",
		},
		{
			"<leader>cF",
			function()
				require("sidekick.cli").send({ msg = "{file}" })
			end,
			desc = "Sidekick: Send file",
		},
		{
			"<leader>cd",
			function()
				require("sidekick.cli").close()
			end,
			desc = "Sidekick: Detach CLI",
		},
		{
			"<leader>c1",
			function()
				require("sidekick.cli").toggle({ name = "claude", focus = true })
			end,
			desc = "Sidekick: Claude Code",
		},
		{
			"<leader>c2",
			function()
				require("sidekick.cli").toggle({ name = "cursor", focus = true })
			end,
			desc = "Sidekick: Cursor Agent",
		},
		{
			"<leader>c3",
			function()
				require("sidekick.cli").toggle({ name = "droid", focus = true })
			end,
			desc = "Sidekick: Factory Droid",
		},
		{
			"<leader>c4",
			function()
				require("sidekick.cli").toggle({ name = "opencode", focus = true })
			end,
			desc = "Sidekick: OpenCode",
		},
		-- Hidden tasks in minimized Rex floats (lua/sidekick_ext/tasks.lua)
		{
			"<leader>jn",
			function()
				require("sidekick_ext.tasks").prompt()
			end,
			mode = { "n", "v" },
			desc = "Agent: new session (<C-s> starts hidden)",
		},
		{
			"<leader>jo",
			function()
				require("sidekick_ext.tasks").prompt({ show = true })
			end,
			mode = { "n", "v" },
			desc = "Agent: new session (<C-s> starts visible)",
		},
		{
			"<leader>jj",
			function()
				require("sidekick_ext.tasks").pick()
			end,
			desc = "Agent: sessions (show / hide / send / kill)",
		},
		{
			"<leader>jh",
			function()
				require("sidekick_ext.tasks").hide_all()
			end,
			desc = "Agent: hide all session floats",
		},
		-- Review comments (lua/sidekick_ext/review.lua)
		{
			"<leader>mr",
			function()
				require("sidekick_ext.review").toggle_mode()
			end,
			desc = "Review: toggle review mode (inline diff + hunk list)",
		},
		{
			"<leader>ma",
			function()
				require("sidekick_ext.review").add()
			end,
			mode = { "n", "v" },
			desc = "Review: add/edit comment",
		},
		{
			"<leader>md",
			function()
				require("sidekick_ext.review").delete()
			end,
			desc = "Review: delete comment",
		},
		{
			"<leader>ml",
			function()
				require("sidekick_ext.review").list()
			end,
			desc = "Review: list comments",
		},
		{
			"<leader>ms",
			function()
				require("sidekick_ext.review").send()
			end,
			desc = "Review: send comments",
		},
		{
			"<leader>mc",
			function()
				if vim.fn.confirm("Clear all review comments?", "&Yes\n&No", 2) == 1 then
					require("sidekick_ext.review").clear()
				end
			end,
			desc = "Review: clear comments",
		},
	},
}
