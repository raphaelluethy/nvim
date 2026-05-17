return { -- Fuzzy Finder (files, lsp, etc)
	"nvim-telescope/telescope.nvim",
	tag = "v0.1.9",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ -- If encountering errors, see telescope-fzf-native README for installation instructions
			"nvim-telescope/telescope-fzf-native.nvim",

			-- `build` is used to run some command when the plugin is installed/updated.
			-- This is only run then, not every time Neovim starts up.
			build = "make",

			-- `cond` is a condition used to determine whether this plugin should be
			-- installed and loaded.
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-telescope/telescope-ui-select.nvim" }, -- Useful for getting pretty icons, but requires a Nerd Font.
		{
			"nvim-tree/nvim-web-devicons",
			enabled = vim.g.have_nerd_font,
		},
	},
	config = function()
		-- See `:help telescope` and `:help telescope.setup()`
		local previewers = require("telescope.previewers")
		local default_buffer_previewer = previewers.buffer_previewer_maker

		local function buffer_previewer_maker(filepath, bufnr, opts)
			filepath = vim.fn.expand(filepath)
			vim.uv.fs_stat(filepath, function(_, stat)
				if not stat then
					return
				end

				if stat.size > 1024 * 1024 then
					vim.schedule(function()
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

		-- Enable Telescope extensions if they are installed
		pcall(require("telescope").load_extension, "fzf")
		pcall(require("telescope").load_extension, "ui-select")

		-- See `:help telescope.builtin`
		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>sh", builtin.help_tags, {
			desc = "[S]earch [H]elp",
		})
		vim.keymap.set("n", "<leader>sk", builtin.keymaps, {
			desc = "[S]earch [K]eymaps",
		})
		vim.keymap.set("n", "<leader>sF", builtin.find_files, {
			desc = "[S]earch [F]iles (Telescope)",
		})
		local function find_all_files()
			local find_command = {
				"rg",
				"--files",
				"--hidden",
				"--no-ignore-vcs",
			}
			local extra_ignores = {
				"!.git/*",
				"!node_modules/*",
				"!dist/*",
				"!dist-ssr/*",
			}
			for _, glob in ipairs(extra_ignores) do
				table.insert(find_command, "--glob")
				table.insert(find_command, glob)
			end
			builtin.find_files({ find_command = find_command })
		end

		vim.keymap.set("n", "<leader>sa", find_all_files, {
			desc = "[S]earch [A]ll Files",
		})
		vim.keymap.set("n", "<leader>sp", builtin.git_files, {
			desc = "[S]earch [P]roject",
		})
		vim.keymap.set("n", "<leader>ss", builtin.builtin, {
			desc = "[S]earch [S]elect Telescope",
		})
		vim.keymap.set("n", "<leader>sW", builtin.grep_string, {
			desc = "[S]earch current [W]ord (Telescope)",
		})
		vim.keymap.set("n", "<leader>sT", builtin.live_grep, {
			desc = "[S]earch by grep (Telescope)",
		})
		vim.keymap.set("n", "<leader>sd", builtin.diagnostics, {
			desc = "[S]earch [D]iagnostics",
		})
		vim.keymap.set("n", "<leader>sr", builtin.resume, {
			desc = "[S]earch [R]esume",
		})
		vim.keymap.set("n", "<leader>s.", builtin.oldfiles, {
			desc = '[S]earch Recent Files ("." for repeat)',
		})
		vim.keymap.set("n", "<leader><leader>", builtin.buffers, {
			desc = "[ ] Find existing buffers",
		})

		-- Slightly advanced example of overriding default behavior and theme
		vim.keymap.set("n", "<leader>/", function()
			-- You can pass additional configuration to Telescope to change the theme, layout, etc.
			builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
				winblend = 10,
				previewer = false,
			}))
		end, {
			desc = "[/] Fuzzily search in current buffer",
		})

		-- It's also possible to pass additional configuration options.
		--  See `:help telescope.builtin.live_grep()` for information about particular keys
		vim.keymap.set("n", "<leader>s/", function()
			builtin.live_grep({
				grep_open_files = true,
				prompt_title = "Live Grep in Open Files",
			})
		end, {
			desc = "[S]earch [/] in Open Files",
		})

		-- Shortcut for searching your Neovim configuration files
		vim.keymap.set("n", "<leader>sn", function()
			builtin.find_files({
				cwd = vim.fn.stdpath("config"),
			})
		end, {
			desc = "[S]earch [N]eovim files",
		})
	end,
}
