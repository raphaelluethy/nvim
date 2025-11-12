return {
	{
		"loctvl842/monokai-pro.nvim",
		config = function()
			require("monokai-pro").setup({
				filter = "spectrum",
				transparent_background = true,
				indent_blankline = {
					context_highlight = "pro", -- default | pro
					context_start_underline = false,
				},
			})

			local function run_theme()
				vim.cmd.colorscheme("monokai-pro")
				--     vim.cmd.hi 'Comment gui=none'
				--     local set_hl_for_floating_window = function()
				--         vim.api.nvim_set_hl(0, 'FloatBorder', {
				--             fg = '#ffffff',
				--             bg = 'none'
				--         })
				--     end

				--     set_hl_for_floating_window()

				--     vim.api.nvim_create_autocmd('ColorScheme', {
				--         pattern = '*',
				--         desc = 'Avoid overwritten by loading color schemes later',
				--         callback = set_hl_for_floating_window
				--     })
			end

			run_theme()
		end,
	}, -- Highlight todo, notes, etc in comments
}
