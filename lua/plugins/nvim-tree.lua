return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	init = function()
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
	end,
	cmd = { "NvimTreeToggle", "NvimTreeFindFile", "NvimTreeFocus" },
	keys = {
		{
			"<leader>ft",
			"<cmd>NvimTreeToggle<cr>",
			desc = "Toggle file tree",
		},
	},
	opts = {
		disable_netrw = true,
		hijack_netrw = true,
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
				quit_on_open = true,
			},
		},
	},
	config = function(_, opts)
		require("nvim-tree").setup(opts)
		vim.api.nvim_create_autocmd("VimEnter", {
			group = vim.api.nvim_create_augroup("NvimTreeStartup", { clear = true }),
			callback = function()
				if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified then
					require("nvim-tree.api").tree.open()
				end
			end,
		})
	end,
}
