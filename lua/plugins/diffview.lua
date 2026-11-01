-- Review panel: file tree (staged / unstaged sections) + side-by-side diff.
-- The right side is the real working-tree file, so edits and review comments
-- (lua/sidekick_ext/review.lua) work there. Opened with <leader>mr.
return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	opts = function()
		local actions = require("diffview.actions")
		return {
			enhanced_diff_hl = true,
			view = {
				default = { layout = "diff2_horizontal", winbar_info = true },
			},
			file_panel = {
				listing_style = "tree",
				win_config = { position = "left", width = 40 },
			},
			keymaps = {
				file_panel = {
					{ "n", "<space>", actions.toggle_fold, { desc = "Toggle fold" } },
					{ "n", "s", actions.toggle_stage_entry, { desc = "Stage / unstage" } },
					{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close review" } },
				},
				view = {
					{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close review" } },
				},
			},
			hooks = {
				-- Key hints that stay visible in the file panel.
				view_opened = function()
					vim.schedule(function()
						for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
							if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "DiffviewFiles" then
								vim.wo[win].winbar = "%#Comment# <CR>%* open %#Comment#<Space>%* fold %#Comment#s%* stage %#Comment#q%* close"
							end
						end
					end)
				end,
			},
		}
	end,
}
