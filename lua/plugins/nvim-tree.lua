return {
	"nvim-tree/nvim-tree.lua",
	dependencies = {
		{
			"nvim-tree/nvim-web-devicons",
			enabled = vim.g.have_nerd_font,
		},
	},
	cmd = { "NvimTreeToggle", "NvimTreeFindFile", "NvimTreeFocus" },
	keys = {
		{
			"<leader>ft",
			"<cmd>NvimTreeToggle<cr>",
			desc = "Toggle file tree",
		},
	},
	opts = {
		disable_netrw = false,
		hijack_netrw = false,
		hijack_cursor = true,
		sync_root_with_cwd = true,
		view = {
			width = 32,
			side = "left",
		},
		renderer = {
			group_empty = true,
			highlight_git = true,
			icons = {
				show = {
					file = vim.g.have_nerd_font,
					folder = vim.g.have_nerd_font,
					folder_arrow = vim.g.have_nerd_font,
					git = true,
				},
			},
		},
		filters = {
			dotfiles = false,
			git_ignored = false,
		},
		git = {
			enable = true,
		},
		actions = {
			open_file = {
				quit_on_open = false,
			},
		},
	},
}
