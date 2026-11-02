-- Review panel (<leader>mr): file explorer with staged / unstaged groups and a
-- VS Code style diff. `t` switches between side-by-side and unified (inline),
-- ]c/[c next/prev hunk, ]f/[f next/prev file, - stage/unstage, q close.
-- Note: downloads a prebuilt diff library on first use (`:CodeDiff install`).
return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	opts = {
		diff = {
			layout = "side-by-side", -- or "inline" (unified); toggle with `t`
			-- ]c / [c past the last / first hunk continue into the next / previous file.
			cycle_hunks_across_files = true,
		},
		explorer = {
			position = "left",
			width = 40,
			view_mode = "tree",
		},
		-- codediff installs buffer-local maps in the diff panes (the right pane
		-- is your real file buffer). Keep them off prefixes used globally:
		-- <leader>e is Harpoon, <leader>c* is code/agents, <leader>ct the terminal.
		-- `g?` in a diff pane lists what is active.
		keymaps = {
			view = {
				toggle_explorer = false, -- semantic panel: t / q; explorer: <leader>mr again
				focus_explorer = false, -- use <C-w>h
				-- <leader>hs / <leader>hu / <leader>hr stay: same meaning as gitsigns' hunk keys.
			},
			conflict = {
				accept_incoming = "<leader>Mt",
				accept_current = "<leader>Mo",
				accept_both = "<leader>Mb",
				discard = "<leader>Mx",
				accept_all_incoming = "<leader>MT",
				accept_all_current = "<leader>MO",
				accept_all_both = "<leader>MB",
				discard_all = "<leader>MX",
			},
		},
	},
}
