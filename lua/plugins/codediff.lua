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
	},
}
