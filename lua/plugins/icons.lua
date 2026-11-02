-- mini.icons provides icons for oil, telescope, nvim-tree, trouble and blink.
-- `mock_nvim_web_devicons` makes it answer `require("nvim-web-devicons")` so
-- plugins written against devicons work without that dependency.
return {
	"echasnovski/mini.icons",
	version = "*",
	lazy = false,
	config = function()
		require("mini.icons").setup()
		MiniIcons.mock_nvim_web_devicons()
	end,
}
