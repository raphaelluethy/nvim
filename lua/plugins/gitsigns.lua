-- Stage / reset the hunk under the cursor, or only the selected lines.
local function hunk_op(name)
	local gs = require("gitsigns")
	if vim.fn.mode():match("[vV]") then
		gs[name]({ vim.fn.line("."), vim.fn.line("v") })
	else
		gs[name]()
	end
end

return {
	"lewis6991/gitsigns.nvim",
	version = "*",
	opts = {
		signcolumn = true,
		linehl = false, -- Set true to highlight changed lines.
		word_diff = true, -- Highlight changed text within lines.
	},
	keys = {
		{
			"<leader>hp",
			"<cmd>Gitsigns preview_hunk<cr>",
			desc = "Preview Git hunk in a floating window",
		},
		-- Same keys codediff uses in its diff panes (lua/plugins/codediff.lua).
		{
			"<leader>hs",
			function()
				hunk_op("stage_hunk")
			end,
			mode = { "n", "x" },
			desc = "Stage / unstage hunk",
		},
		{
			"<leader>hr",
			function()
				hunk_op("reset_hunk")
			end,
			mode = { "n", "x" },
			desc = "Reset hunk",
		},
		{ "<leader>hb", "<cmd>Gitsigns blame_line<cr>", desc = "Blame line" },
		{
			"]h",
			"<cmd>Gitsigns nav_hunk next<cr>",
			desc = "Next Git hunk",
		},
		{
			"[h",
			"<cmd>Gitsigns nav_hunk prev<cr>",
			desc = "Previous Git hunk",
		},
	},
}
