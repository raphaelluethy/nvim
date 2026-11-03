return {
	"folke/sidekick.nvim",
	version = "*",
	lazy = false,
	-- Agent windows, Rex sessions and tasks are panels.nvim panels.
	dependencies = { "panels.nvim" },
	opts = {
		nes = { enabled = false },
		cli = {
			picker = "telescope",
			win = {
				layout = "right",
				-- Ctrl-h/j/k/l leave agent terminals like any window, floats
				-- included, and continue into Rex panes (panels.nvim).
				keys = {
					nav_left = {
						"<c-h>",
						function()
							require("panels").navigate("h")
						end,
						mode = "t",
						expr = false,
					},
					nav_down = {
						"<c-j>",
						function()
							require("panels").navigate("j")
						end,
						mode = "t",
						expr = false,
					},
					nav_up = {
						"<c-k>",
						function()
							require("panels").navigate("k")
						end,
						mode = "t",
						expr = false,
					},
					nav_right = {
						"<c-l>",
						function()
							require("panels").navigate("l")
						end,
						mode = "t",
						expr = false,
					},
				},
			},
			tools = {
				opencode = { cmd = { "opencode" } },
				droid = { cmd = { "droid" } },
			},
		},
	},
	config = function(_, opts)
		require("sidekick").setup(opts)
		-- Agent windows are panels; Rex sessions are a sidekick backend.
		require("sidekick_ext.panels").setup()
		require("sidekick_ext.agents").setup()
		-- Agents get the current file / cursor / selection with every prompt
		-- (hooks call bin/agent-editor-context).
		require("sidekick_ext.context").setup()
		require("sidekick_ext.sessions").setup()
		-- Tasks run in Rex or as Neovim sessions per the "tasks" switch in
		-- lua/plugins/panels.lua.
		require("sidekick_ext.tasks").setup()
		require("sidekick_ext.review").setup()
	end,
	keys = {
		-- Agent sessions inside Neovim (lua/sidekick_ext/sessions.lua).
		-- Several agents can run at once; the "active" one is the session you
		-- last entered. Pane sessions share the right split, floats stack.
		{
			"<leader>cc",
			function()
				require("sidekick_ext.sessions").toggle_or_start()
			end,
			desc = "Agent: toggle active session (none: pick agent and start)",
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
				-- Running sessions (also tmux / zellij) attach; a new agent starts
				-- through sidekick_ext.sessions, so it follows the "agents" switch.
				require("sidekick.cli").select({
					filter = { installed = true },
					cb = function(state)
						if not state then
							return
						end
						local panel = state.session and state.session.panel
						if panel then -- a Rex session (panels backend)
							local Sessions = require("sidekick_ext.sessions")
							for _, s in ipairs(Sessions.list()) do
								if s.panel == panel then
									return Sessions.show(s)
								end
							end
							return panel:show({ focus = true })
						end
						if state.session or state.started then
							local State = require("sidekick.cli.state")
							if state.external then
								local terminal = require("sidekick.cli.terminal").new({ tool = state.tool })
								state = State.get_state(terminal)
							end
							return State.attach(state, { show = true, focus = true })
						end
						require("sidekick_ext.sessions").new({ tool = state.tool.name, layout = "right" })
					end,
				})
			end,
			desc = "Agent: select CLI (running / mux sessions, or start one)",
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
				require("sidekick.cli").send({
					msg = "{position}\n```\n{selection}\n```",
					filter = require("sidekick_ext.sessions").filter(),
				})
			end,
			mode = "v",
			desc = "Agent: send selection with file and position",
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
