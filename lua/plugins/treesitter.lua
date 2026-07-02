return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	opts = {
		ensure_installed = {
			"go",
			"gomod",
			"gosum",
			"gotmpl",
			"gowork",
			"lua",
			"vim",
			"vimdoc",
		},
	},
	config = function(_, opts)
		require("nvim-treesitter").setup()
		require("nvim-treesitter").install(opts.ensure_installed)

		local function start_treesitter(bufnr)
			if vim.bo[bufnr].filetype == "" then
				return
			end

			if pcall(vim.treesitter.start, bufnr) then
				vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("raphaelluethy-treesitter", {
				clear = true,
			}),
			pattern = "*",
			callback = function(event)
				start_treesitter(event.buf)
			end,
		})

		start_treesitter(vim.api.nvim_get_current_buf())
	end,
}
