return {
	"stevearc/oil.nvim",
	version = "*",
	-- Not lazy: oil must be loaded at startup to take over `nvim <dir>`.
	lazy = false,
	dependencies = { "echasnovski/mini.icons" },
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {
		default_file_explorer = true,
		view_options = { show_hidden = true },
	},
	keys = {
		{ "-", "<CMD>Oil<CR>", desc = "Open Oil.nvim" },
	},
	config = function(_, opts)
		require("oil").setup(opts)
		-- `nvim` with no file args: open the project root in oil.
		vim.api.nvim_create_autocmd("VimEnter", {
			group = vim.api.nvim_create_augroup("OilStartup", { clear = true }),
			nested = true, -- let oil's BufEnter/BufWinEnter autocmds run
			callback = function()
				if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified then
					require("oil").open(vim.uv.cwd())
				end
			end,
		})
	end,
}
