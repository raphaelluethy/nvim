local function picker(source, opts)
	return function()
		require("snacks.picker")[source](opts)
	end
end

local all_files_exclude = { ".git", "node_modules", "dist", "dist-ssr", ".next", "target" }

return {
	"folke/snacks.nvim",
	version = "*",
	priority = 1000,
	lazy = false,
	opts = {
		picker = {
			enabled = true,
			ui_select = true,
		},
	},
	keys = {
		{ "<leader>sh", picker("help"), desc = "[S]earch [H]elp" },
		{ "<leader>sk", picker("keymaps"), desc = "[S]earch [K]eymaps" },
		{
			"<leader>sa",
			picker("files", { hidden = true, ignored = true, exclude = all_files_exclude }),
			desc = "[S]earch [A]ll Files",
		},
		{ "<leader>sp", picker("git_files"), desc = "[S]earch [P]roject" },
		{ "<leader>sb", picker("pickers"), desc = "[S]earch Snacks pickers" },
		{ "<leader>sd", picker("diagnostics"), desc = "[S]earch [D]iagnostics" },
		{ "<leader>sr", picker("resume"), desc = "[S]earch [R]esume (Snacks)" },
		{ "<leader>s.", picker("recent"), desc = "[S]earch Recent Files" },
		{ "<leader><leader>", picker("buffers"), desc = "[ ] Find existing buffers" },
		{ "<leader>/", picker("lines"), desc = "[/] Search in current buffer" },
		{ "<leader>s/", picker("grep_buffers"), desc = "[S]earch [/] in Open Buffers" },
		{
			"<leader>sn",
			picker("files", { cwd = vim.fn.stdpath("config") }),
			desc = "[S]earch [N]eovim files",
		},
	},
}
