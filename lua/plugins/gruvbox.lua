return {
	'f4z3r/gruvbox-material.nvim',
	name = 'gruvbox-material',
	lazy = false,
	priority = 1000,
	opts = {},
	config = function()
		require('gruvbox-material').setup({
			italics = true, -- enable italics in general
			contrast = "medium", -- set contrast, can be any of "hard", "medium", "soft"
			comments = {
				italics = true, -- enable italic comments
			},
			background = {
				transparent = true, -- set the background to be opaque
			},
			float = {
				force_background = false, -- set to true to force backgrounds on floats even when
				-- background.transparent is set
				background_color = nil, -- set color for float backgrounds. If nil, uses the default color set
				-- by the color scheme
			},
			signs = {
				force_background = false, -- set to true to force backgrounds on signs even when
				-- background.transparent is set
				background_color = nil, -- set color for sign backgrounds. If nil, uses the default color set
				-- by the color scheme
			},
			customize = nil, -- customize the theme in any way you desire, see below what this
			-- configuration accepts
		})
	end,
	init = function()
		vim.cmd [[colorscheme gruvbox-material]]
	end,
}
