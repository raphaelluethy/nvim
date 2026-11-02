return { -- Fuzzy Finder (files, lsp, etc)
	"nvim-telescope/telescope.nvim",
	version = "*",
	-- Loaded on first use: :Telescope, one of the keys below, `require` from
	-- lsp.lua / neogit / sidekick, or the first vim.ui.select() call.
	cmd = "Telescope",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ -- If encountering errors, see telescope-fzf-native README for installation instructions
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-telescope/telescope-ui-select.nvim" },
	},
	init = function()
		-- Route vim.ui.select through Telescope without loading it at startup.
		local original = vim.ui.select
		vim.ui.select = function(...)
			vim.ui.select = original
			require("lazy").load({ plugins = { "telescope.nvim" } })
			return vim.ui.select(...)
		end
	end,
	keys = function()
		local function builtin(name, opts)
			return function()
				require("telescope.builtin")[name](opts)
			end
		end
		local function find_all_files()
			local find_command = { "rg", "--files", "--hidden", "--no-ignore-vcs" }
			for _, glob in ipairs({ "!.git/*", "!node_modules/*", "!dist/*", "!dist-ssr/*" }) do
				table.insert(find_command, "--glob")
				table.insert(find_command, glob)
			end
			require("telescope.builtin").find_files({ find_command = find_command })
		end
		return {
			{ "<leader>sh", builtin("help_tags"), desc = "[S]earch [H]elp" },
			{ "<leader>sk", builtin("keymaps"), desc = "[S]earch [K]eymaps" },
			{ "<leader>sf", builtin("find_files"), desc = "[S]earch [F]iles" },
			{ "<leader>sa", find_all_files, desc = "[S]earch [A]ll Files" },
			{ "<leader>sp", builtin("git_files"), desc = "[S]earch [P]roject" },
			{ "<leader>ss", builtin("builtin"), desc = "[S]earch [S]elect Telescope" },
			{ "<leader>sw", builtin("grep_string"), desc = "[S]earch current [W]ord" },
			{ "<leader>sg", builtin("live_grep"), desc = "[S]earch by [G]rep" },
			{
				"<leader>sG",
				builtin("live_grep", { additional_args = { "--fixed-strings" } }),
				desc = "[S]earch [G]rep (plain)",
			},
			{ "<leader>sd", builtin("diagnostics"), desc = "[S]earch [D]iagnostics" },
			{ "<leader>sr", builtin("resume"), desc = "[S]earch [R]esume" },
			{ "<leader>s.", builtin("oldfiles"), desc = '[S]earch Recent Files ("." for repeat)' },
			{ "<leader><leader>", builtin("buffers"), desc = "[ ] Find existing buffers" },
			{
				"<leader>/",
				function()
					require("telescope.builtin").current_buffer_fuzzy_find(
						require("telescope.themes").get_dropdown({ winblend = 10, previewer = false })
					)
				end,
				desc = "[/] Fuzzily search in current buffer",
			},
			{
				"<leader>s/",
				builtin("live_grep", { grep_open_files = true, prompt_title = "Live Grep in Open Files" }),
				desc = "[S]earch [/] in Open Files",
			},
			{
				"<leader>sn",
				builtin("find_files", { cwd = vim.fn.stdpath("config") }),
				desc = "[S]earch [N]eovim files",
			},
		}
	end,
	config = function()
		local previewers = require("telescope.previewers")
		local default_buffer_previewer = previewers.buffer_previewer_maker

		-- Skip previews of files over 1 MB.
		local function buffer_previewer_maker(filepath, bufnr, opts)
			filepath = vim.fn.expand(filepath)
			vim.uv.fs_stat(filepath, function(_, stat)
				if not stat then
					return
				end
				if stat.size > 1024 * 1024 then
					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(bufnr) then
							return
						end
						local size = string.format("%.1f", stat.size / 1024 / 1024)
						vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
							"Preview skipped",
							"",
							("File is %s MB. Use <CR> to open it."):format(size),
						})
					end)
					return
				end
				default_buffer_previewer(filepath, bufnr, opts)
			end)
		end

		require("telescope").setup({
			defaults = {
				buffer_previewer_maker = buffer_previewer_maker,
				file_ignore_patterns = {
					"%.git/",
					"node_modules/",
					"dist/",
					"dist%-ssr/",
					"%.next/",
					"target/",
				},
				preview = {
					filesize_limit = 1,
					timeout = 250,
				},
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden",
					"--max-columns=240",
					"--max-columns-preview",
					"--glob=!.git/*",
					"--glob=!node_modules/*",
					"--glob=!dist/*",
					"--glob=!dist-ssr/*",
					"--glob=!.next/*",
					"--glob=!target/*",
				},
			},
			extensions = {
				["ui-select"] = { require("telescope.themes").get_dropdown() },
			},
		})

		pcall(require("telescope").load_extension, "fzf")
		pcall(require("telescope").load_extension, "ui-select")
	end,
}
