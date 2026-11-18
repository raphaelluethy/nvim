-- 99 (local fork): in-buffer AI edits on <leader>9.
-- Backends: "claude" (Claude Agent SDK; Claude Code login or ANTHROPIC_API_KEY)
-- or "opencode" (opencode CLI). An explicit `provider = ...` overrides `backend`.
local function action(method, module)
	return function()
		require(module or "99")[method]()
	end
end

return {
	"raphaelluethy/99",
	dir = vim.fn.expand("~/Documents/projects/private/99"),
	name = "99",
	main = "99",
	opts = {
		backend = "claude",
		model = "opus", -- "opus", "haiku", or a full model id
		-- backend = "opencode",
		-- model = "opencode/claude-sonnet-5-5", -- opencode's built-in default no longer exists
		-- tmp_dir = "./tmp",
		completion = {
			source = "native",
		},
		md_files = {
			"AGENTS.md",
		},
		in_flight_options = { agent_trace = { enable = true, max_lines = 8 } },
	},
	keys = {
		{ "<leader>9s", action("search"), desc = "99 search" },
		{ "<leader>9f", action("vibe"), desc = "99 vibe" },
		{ "<leader>9v", action("visual"), mode = "v", desc = "99 visual" },
		{ "<leader>9t", action("tutorial"), mode = { "n", "v" }, desc = "99 tutorial" },
		{ "<leader>9x", action("stop_all_requests"), mode = { "n", "v" }, desc = "99 stop requests" },
		{ "<leader>9o", action("open"), desc = "99 open last result" },
		{ "<leader>9l", action("view_logs"), desc = "99 logs" },
		{ "<leader>9c", action("clear_previous_requests"), desc = "99 clear requests" },
		{ "<leader>9m", action("select_model", "99.extensions.telescope"), desc = "99 select model" },
		-- Not <leader>9sp: that would make <leader>9s wait for a third key.
		{ "<leader>9p", action("select_provider", "99.extensions.telescope"), desc = "99 select provider" },
	},
}
