return {
	"nvim-mini/mini.nvim",
	version = false,

	config = function()
		local statusline = require("mini.statusline")
		-- set use_icons to true if you have a Nerd Font
		statusline.setup({ use_icons = vim.g.have_nerd_font })

		---@diagnostic disable-next-line: duplicate-set-field
		statusline.section_location = function()
			return "%2l:%-2v"
		end

		local notify = require("mini.notify")
		notify.setup({
			lsp_progress = {
				enable = false,
			},
		})

		local starter = require("mini.starter")
		starter.setup()
	end,
}
