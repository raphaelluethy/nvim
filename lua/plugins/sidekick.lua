return {
	"folke/sidekick.nvim",
	cmd = "Sidekick",
	opts = {
		-- Supermaven remains the only AI completion provider.
		nes = { enabled = false },
		copilot = { status = { enabled = false } },
		cli = {
			picker = "telescope",
			tools = {
				cursor = { cmd = { "agent" } },
				droid = { cmd = { "droid" } },
			},
		},
	},
	keys = {
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
	},
}
