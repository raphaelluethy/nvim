return {
	"nvim-treesitter/nvim-treesitter",
	-- The rewrite lives on main; tagged releases are the frozen master branch.
	branch = "main",
	build = ":TSUpdate",
	opts = {
		ensure_installed = {
			"go",
			"gomod",
			"gosum",
			"gotmpl",
			"gowork",
			"java",
			"kotlin",
			"lua",
			"odin",
			"vim",
			"vimdoc",
		},
	},
	config = function(_, opts)
		local ts = require("nvim-treesitter")
		ts.setup()

		local function start_treesitter(bufnr)
			if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype == "" then
				return
			end

			if pcall(vim.treesitter.start, bufnr) then
				vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end
		end

		local function restart_windows(lang)
			vim.schedule(function()
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local buf = vim.api.nvim_win_get_buf(win)
					if not lang or vim.treesitter.language.get_lang(vim.bo[buf].filetype) == lang then
						start_treesitter(buf)
					end
				end
			end)
		end

		-- A parser whose queries link points nowhere (left behind when the
		-- plugin moved) highlights nothing; reinstall it to relink them.
		local function broken_parsers()
			local queries = require("nvim-treesitter.config").get_install_dir("queries")
			return vim.tbl_filter(function(lang)
				return vim.uv.fs_stat(vim.fs.joinpath(queries, lang)) == nil
			end, ts.get_installed("parsers"))
		end

		ts.install(broken_parsers(), { force = true }):await(function()
			ts.install(opts.ensure_installed):await(function()
				restart_windows()
			end)
		end)

		-- Install the parser for any filetype that has one on first use.
		local installing = {}
		local function ensure_parser(bufnr)
			local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
			if not lang or installing[lang] or vim.treesitter.language.add(lang) then
				return false
			end
			if not vim.list_contains(ts.get_available(), lang) then
				return false
			end
			installing[lang] = true
			ts.install({ lang }):await(function()
				restart_windows(lang)
			end)
			return true
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("raphaelluethy-treesitter", {
				clear = true,
			}),
			pattern = "*",
			callback = function(event)
				if not ensure_parser(event.buf) then
					start_treesitter(event.buf)
				end
			end,
		})

		start_treesitter(vim.api.nvim_get_current_buf())
	end,
}
