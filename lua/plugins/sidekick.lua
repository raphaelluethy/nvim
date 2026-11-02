return {
	"folke/sidekick.nvim",
	version = "*",
	-- Loaded at startup: next edit suggestions (NES) attach to the Copilot LSP.
	lazy = false,
	opts = {
		cli = {
			picker = "telescope",
			win = { layout = "right" },
			tools = {
				opencode = { cmd = { "opencode" } },
				droid = { cmd = { "droid" } },
			},
		},
	},
	config = function(_, opts)
		require("sidekick").setup(opts)
		require("sidekick_ext.agents").setup()
		require("sidekick_ext.sessions").setup()
		require("sidekick_ext.tasks").setup({
			backend = "buffer", -- "buffer" or "rex"; applies to visible and hidden tasks
		})
		require("sidekick_ext.review").setup()
		-- Semantic change groups (<leader>mg): model ids are opencode provider/model.
		require("sidekick_ext.semantic").setup({
			llm = { model = "openai/gpt-6.1-terra-fast" },
		})

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
		-- Agent sessions inside Neovim (lua/sidekick_ext/sessions.lua).
		-- Several agents can run at once; the "active" one is the session you
		-- last entered. Pane sessions share the right split, floats stack.
		{
			"<leader>cc",
			function()
				local State = require("sidekick.cli.state")
				local attached = State.get({ attached = true, external = false })
				if #attached > 0 then
					return require("sidekick.cli").toggle({ filter = { attached = true, external = false } })
				end
				require("sidekick.cli").select({
					filter = { installed = true },
					cb = function(state)
						if not state then
							return
						end
						if state.external then
							local terminal = require("sidekick.cli.terminal").new({ tool = state.tool })
							state = State.get_state(terminal)
						end
						State.attach(state, { show = true, focus = true })
					end,
				})
			end,
			desc = "Sidekick: Toggle CLI",
		},
		{
			"<leader>cn",
			function()
				require("sidekick_ext.tasks").prompt({ show = true })
			end,
			mode = { "n", "v" },
			desc = "Agent: submit task and open terminal",
		},
		{
			"<leader>cN",
			function()
				require("sidekick_ext.sessions").prompt({ layout = "float" })
			end,
			mode = { "n", "v" },
			desc = "Agent: new session (<C-s> starts as float)",
		},
		{
			"<leader>cj",
			function()
				require("sidekick_ext.sessions").pick()
			end,
			desc = "Agent: sessions (show / float / hide / send / rename / kill)",
		},
		{
			"<leader>c]",
			function()
				require("sidekick_ext.sessions").cycle(1)
			end,
			desc = "Agent: next session",
		},
		{
			"<leader>c[",
			function()
				require("sidekick_ext.sessions").cycle(-1)
			end,
			desc = "Agent: previous session",
		},
		{
			"<leader>cw",
			function()
				local S = require("sidekick_ext.sessions")
				local s = S.get_active()
				if s then
					S.toggle_float(s)
				end
			end,
			desc = "Agent: active session pane <-> float",
		},
		{
			"<leader>ch",
			function()
				require("sidekick_ext.sessions").hide_all()
			end,
			desc = "Agent: hide all sessions",
		},
		{
			"<leader>cx",
			function()
				local S = require("sidekick_ext.sessions")
				local s = S.get_active()
				if s and vim.fn.confirm("Kill session '" .. s.title .. "'?", "&Yes\n&No", 2) == 1 then
					S.kill(s)
				end
			end,
			desc = "Agent: kill active session",
		},
		{
			"<leader>cl",
			function()
				require("sidekick.cli").select({ filter = { installed = true } })
			end,
			desc = "Sidekick: Select CLI (external / mux sessions)",
		},
		-- Context goes to the active session.
		{
			"<leader>cA",
			function()
				require("sidekick.cli").prompt({
					cb = function(_, text)
						if text then
							require("sidekick.cli").send({
								text = text,
								filter = require("sidekick_ext.sessions").filter(),
							})
						end
					end,
				})
			end,
			mode = { "n", "v" },
			desc = "Agent: send prompt template",
		},
		{
			"<leader>ci",
			function()
				require("sidekick.cli").send({ msg = "{this}", filter = require("sidekick_ext.sessions").filter() })
			end,
			mode = { "n", "v" },
			desc = "Agent: send cursor context",
		},
		{
			"<leader>cs",
			function()
				require("sidekick.cli").send({ msg = "{selection}", filter = require("sidekick_ext.sessions").filter() })
			end,
			mode = "v",
			desc = "Agent: send selection",
		},
		{
			"<leader>cF",
			function()
				require("sidekick.cli").send({ msg = "{file}", filter = require("sidekick_ext.sessions").filter() })
			end,
			desc = "Agent: send file",
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
			desc = "Review: open review panel (codediff)",
		},
		{
			"<leader>mg",
			function()
				require("sidekick_ext.semantic").toggle()
			end,
			desc = "Review: semantic change groups (LLM)",
		},
		{
			"<leader>mG",
			function()
				local Sem = require("sidekick_ext.semantic")
				local state = Sem.state()
				if state then
					Sem.regroup(state)
				else
					Sem.toggle()
				end
			end,
			desc = "Review: regroup semantic groups",
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
