return {
	{
		"loctvl842/monokai-pro.nvim",
		config = function()
			require("monokai-pro").setup({
				transparent_background = true,
				devicons = true,
				filter = "spectrum", -- classic | octagon | pro | machine | ristretto | spectrum
				inc_search = "background", -- underline | background
				background_clear = {
					"nvim-tree",
					-- "neo-tree",
					-- "bufferline",
					"float_win",
					"telescope",
					"toggleterm",
				},
				plugins = {
					bufferline = {
						underline_selected = true,
						underline_visible = false,
						underline_fill = true,
						bold = false,
					},
				},
				-- override = function(c)
				-- 	return {
				-- 		-- ColorColumn = { bg = c.editor.background },
				-- 		-- Mine
				-- 		DashboardRecent = { fg = c.base.magenta },
				-- 		DashboardProject = { fg = c.base.blue },
				-- 		DashboardConfiguration = { fg = c.base.white },
				-- 		DashboardSession = { fg = c.base.green },
				-- 		DashboardLazy = { fg = c.base.cyan },
				-- 		DashboardServer = { fg = c.base.yellow },
				-- 		DashboardQuit = { fg = c.base.red },
				-- 		IndentBlanklineChar = { fg = c.base.dimmed4 },
				-- 		NeoTreeStatusLine = { link = "StatusLine" },
				-- 		-- mini.hipatterns
				-- 		MiniHipatternsFixme = { fg = c.base.black, bg = c.base.red, bold = true }, -- FIXME
				-- 		MiniHipatternsTodo = { fg = c.base.black, bg = c.base.blue, bold = true }, -- TODO
				-- 		MiniHipatternsHack = { fg = c.base.black, bg = c.base.yellow, bold = true }, -- HACK
				-- 		MiniHipatternsNote = { fg = c.base.black, bg = c.base.green, bold = true }, -- NOTE
				-- 		MiniHipatternsWip = { fg = c.base.black, bg = c.base.cyan, bold = true }, -- WIP
				-- 	}
				-- end,
			})
			vim.cmd([[colorscheme monokai-pro]])
		end,
	},
}
