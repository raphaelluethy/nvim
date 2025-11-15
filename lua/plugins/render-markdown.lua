return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you use the mini.nvim suite
		ft = { "markdown", "norg", "rmd", "org" },
		config = function()
			require("render-markdown").setup({
				code = {
					sign = false,
					width = "block",
					right_pad = 1,
				},
				heading = {
					sign = false,
					icons = {},
				},
				overrides = {
					buftype = {
						nofile = {
							enabled = true,
							code = {
								enabled = true,
								-- disable background
								highlight = "RenderMarkdownCodeNoBg",
							},
							inline_code = {
								highlight = "RenderMarkdownInlineCodeNoBg",
							},
						},
					},
				},
			})
			-- define highlight groups with NO background
			-- vim.api.nvim_set_hl(0, "RenderMarkdownCodeNoBg", { bg = "none", fg = "none" })
			-- vim.api.nvim_set_hl(0, "RenderMarkdownInlineCodeNoBg", { link = "NormalFloat" })
			vim.api.nvim_set_hl(0, "RenderMarkdownCodeNoBg", {
				bg = "#0C0C0C",
			})

			vim.api.nvim_set_hl(0, "RenderMarkdownInlineCodeNoBg", {
				bg = "#0C0C0C",
			})
		end,
	},
}
