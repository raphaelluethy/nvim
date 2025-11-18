return {
	'sainnhe/sonokai',
	lazy = false,
	priority = 1000,
	config = function()
		-- Optionally configure and load the colorscheme
		-- directly inside the plugin declaration.
		vim.g.sonokai_enable_italic = false
		vim.g.sonokai_transparent_background = true
		-- vim.g.sonoai_style = 'sushia'
		vim.g.sonokai_style = 'espresso'
		vim.g.sonokai_float_style = 'blend'
		-- vim.cmd.colorscheme('sonokai')
	end
}
