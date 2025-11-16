return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	---@module "ibl"
	---@type ibl.config
	opts = {
		indent = { char = "▏" },
		scope = {
			enabled = true,
			show_start = false,
			show_end = false,
			char = "▎",
			highlight = "IblScope",
		},
	},
}
