local function picker(module, group, name, local_opts, opts)
	return function()
		require(module)[group][name](local_opts, opts)
	end
end

local function builtin(name, local_opts, opts)
	return picker("mini.pick", "builtin", name, local_opts, opts)
end

local function extra(name, local_opts)
	return picker("mini.extra", "pickers", name, local_opts)
end

local function all_files()
	local command = { "rg", "--files", "--hidden", "--no-ignore-vcs" }
	for _, dir in ipairs({ ".git", "node_modules", "dist", "dist-ssr", ".next", "target" }) do
		table.insert(command, "--glob=!**/" .. dir .. "/**")
	end
	require("mini.pick").builtin.cli({ command = command }, { source = { name = "All files" } })
end

return {
	"nvim-mini/mini.extra",
	version = "*",
	cmd = "Pick",
	opts = {},
	init = function()
		-- Load the Mini picker stack on the first generic selection, not on startup.
		vim.ui.select = function(...)
			require("mini.extra")
			return require("mini.pick").ui_select(...)
		end
	end,
	dependencies = {
		{ "nvim-mini/mini.pick", version = "*", opts = {} },
	},
	keys = {
		{ "<leader>sh", builtin("help"), desc = "[S]earch [H]elp" },
		{ "<leader>sk", extra("keymaps"), desc = "[S]earch [K]eymaps" },
		{ "<leader>sa", all_files, desc = "[S]earch [A]ll Files" },
		{ "<leader>sp", extra("git_files"), desc = "[S]earch [P]roject" },
		{ "<leader>sb", ":Pick <C-d>", desc = "[S]earch Mini pickers" },
		{ "<leader>sd", extra("diagnostic"), desc = "[S]earch [D]iagnostics" },
		{ "<leader>sr", builtin("resume"), desc = "[S]earch [R]esume (Mini)" },
		{ "<leader>s.", extra("oldfiles"), desc = "[S]earch Recent Files" },
		{ "<leader><leader>", builtin("buffers"), desc = "[ ] Find existing buffers" },
		{ "<leader>/", extra("buf_lines", { scope = "current" }), desc = "[/] Search in current buffer" },
		{ "<leader>s/", extra("buf_lines"), desc = "[S]earch [/] in Open Buffers" },
		{
			"<leader>sn",
			builtin("files", nil, { source = { cwd = vim.fn.stdpath("config") } }),
			desc = "[S]earch [N]eovim files",
		},
	},
}
