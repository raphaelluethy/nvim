return {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	dependencies = { -- Automatically install LSPs and related tools to stdpath for Neovim
		{
			"mason-org/mason.nvim",
			config = true,
		}, -- NOTE: Must be loaded before dependants
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim", -- Useful status updates for LSP.
		{
			"j-hui/fidget.nvim",
			opts = {},
		}, -- Allows extra capabilities provided by nvim-cmp
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("raphaelluethy-lsp-attach", {
				clear = true,
			}),
			callback = function(event)
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, {
						buffer = event.buf,
						desc = "LSP: " .. desc,
					})
				end
				map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

				map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

				-- Fuzzy find all the symbols in your current workspace.
				--  Similar to document symbols, except searches over your entire project.
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

				-- map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
					local highlight_augroup = vim.api.nvim_create_augroup("raphaelluethy-lsp-highlight", {
						clear = false,
					})

					-- Set highlight groups with custom colors instead of linking to Visual
					-- This makes the references stand out with a different color
					vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#3a3a3a" })
					vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#3a3a3a" })
					vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#3a3a3a" })

					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = function()
							-- Only enable LSP document highlighting for smaller files
							if vim.api.nvim_buf_line_count(event.buf) <= 3000 then
								vim.lsp.buf.document_highlight()
							end
						end,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("kickstart-lsp-detach", {
							clear = true,
						}),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({
								group = "raphaelluethy-lsp-highlight",
								buffer = event2.buf,
							})
						end,
					})
				end

				-- The following code creates a keymap to toggle inlay hints in your
				-- code, if the language server you are using supports them
				--
				-- This may be unwanted, since they displace some of your code
				if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
					map("<leader>th", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({
							bufnr = event.buf,
						}))
					end, "[T]oggle Inlay [H]ints")
				end
			end,
		})

		local servers = {
			clangd = {},
			gopls = {},
			ty = {},
			rust_analyzer = {},
			vtsls = {},
			--
			--
			emmet_ls = {
				filetypes = {
					"css",
					"eruby",
					"html",
					"javascript",
					"javascriptreact",
					"less",
					"pass",
					"scss",
					"svelte",
					"pug",
					"typescriptreact",
					"vue",
				},
			},
			tinymist = {
				offset_encoding = "utf-8",
			},

			lua_ls = {
				-- cmd = { ... },
				-- filetypes = { ... },
				-- capabilities = {},
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
						diagnostics = {
							-- Define global variables that LuaLS will recognize
							globals = { "vim", "Snacks" }, -- add your globals here
							disable = { "missing-fields" },
						},
						-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
						-- diagnostics = { disable = { 'missing-fields' } },
					},
				},
			},
		}

		-- Ensure the servers and tools above are installed
		--  To check the current status of installed tools and/or manually install
		--  other tools, you can run
		--    :Mason
		--
		--  You can press `g?` for help in this menu.
		require("mason").setup()

		-- You can add other tools here that you want Mason to install
		-- for you, so that they are available from within Neovim.
		local ensure_installed = vim.tbl_keys(servers or {})
		vim.list_extend(ensure_installed, {
			"stylua", -- Used to format Lua code
		})
		require("mason-tool-installer").setup({
			ensure_installed = ensure_installed,
		})

		require("mason-lspconfig").setup({
			ensure_installed = servers,
			automatic_installation = false,
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					-- This handles overriding only values explicitly passed
					-- by the server configuration above. Useful when disabling
					-- certain features of an LSP (for example, turning off formatting for ts_ls)
					server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
					require("lspconfig")[server_name].setup(server)
				end,
			},
		})
	end,
}
