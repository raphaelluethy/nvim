return {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	dependencies = {
		-- LSP installer plugins
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		if vim.fn.exists(":LspInfo") == 0 then
			vim.api.nvim_create_user_command("LspInfo", function()
				vim.cmd("checkhealth vim.lsp")
			end, { desc = "Alias to :checkhealth vim.lsp" })
		end

		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities.textDocument.completion.completionItem.snippetSupport = true
		capabilities.textDocument.completion.completionItem.resolveSupport = {
			properties = {
				"documentation",
				"detail",
				"additionalTextEdits",
			},
		}

		-- LspAttach: Runs when an LSP client attaches to a buffer
		-- Sets up keymaps, document highlighting, and inlay hints
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

				-- Navigation keymaps (matching Zed: g d, g D, g r, g i, g t)
				map("gd", require("telescope.builtin").lsp_definitions, "Goto definition")
				map("gr", require("telescope.builtin").lsp_references, "Goto references")
				map("gI", require("telescope.builtin").lsp_implementations, "Goto implementation")
				map("gD", vim.lsp.buf.declaration, "Goto declaration")
				map("gt", require("telescope.builtin").lsp_type_definitions, "Goto type definition")
				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type definition")

				-- Symbol search keymaps (matching Zed: space o)
				map("<leader>o", require("telescope.builtin").lsp_document_symbols, "Document symbols (Outline)")
				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "Document symbols")
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace symbols")

				-- Code actions
				map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })

				-- Signature help (matching Zed: ctrl-s)
				map("<C-s>", vim.lsp.buf.signature_help, "Signature help")
				map("<C-s>", vim.lsp.buf.signature_help, "Signature help", "i")

				local client = vim.lsp.get_client_by_id(event.data.client_id)

				if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
					vim.lsp.completion.enable(true, client.id, event.buf, {
						autotrigger = true,
						convert = function(item)
							return {
								abbr = item.label:gsub("%b()", ""),
								menu = item.detail,
								kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "",
							}
						end,
					})
				end

				-- Document highlighting: highlights all references to symbol under cursor
				if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
					local highlight_augroup = vim.api.nvim_create_augroup("raphaelluethy-lsp-highlight", {
						clear = false,
					})

					-- Set custom highlight colors for LSP references
					vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#3a3a3a" })
					vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#3a3a3a" })
					vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#3a3a3a" })

					-- CursorHold/CursorHoldI: Highlight references when cursor stops moving
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = function()
							-- Only enable for smaller files to avoid performance issues
							if vim.api.nvim_buf_line_count(event.buf) <= 3000 then
								vim.lsp.buf.document_highlight()
							end
						end,
					})

					-- CursorMoved/CursorMovedI: Clear highlights when cursor moves
					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					-- LspDetach: Clean up highlights when LSP detaches
					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("raphaelluethy-lsp-detach", {
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

				-- Inlay hints: enable by default and add toggle keymap if supported
				if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
					vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
					map("<leader>th", function()
						local bufnr = event.buf
						vim.lsp.inlay_hint.enable(
							not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
							{ bufnr = bufnr }
						)
					end, "[T]oggle Inlay [H]ints")
				end
			end,
		})

		-- LSP servers and their specific settings
		local servers = {
			biome = {},
			clangd = {},
			cssls = {},
			emmet_language_server = {
				filetypes = {
					"astro",
					"css",
					"eruby",
					"html",
					"htmlangular",
					"htmldjango",
					"javascript",
					"javascriptreact",
					"less",
					"scss",
					"sass",
					"svelte",
					"typescriptreact",
					"vue",
				},
			},
			eslint = {
				settings = {
					workingDirectory = { mode = "auto" },
				},
			},
			gopls = {
				cmd = { "gopls" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				root_dir = function(bufnr, on_dir)
					local fname = vim.api.nvim_buf_get_name(bufnr)
					on_dir(vim.fs.root(fname, { "go.work", "go.mod", ".git" }) or vim.fs.dirname(fname))
				end,
				settings = {
					gopls = {
						gofumpt = true,
						staticcheck = true,
						usePlaceholders = true,
						analyses = {
							shadow = true,
							unusedparams = true,
							unusedwrite = true,
						},
						hints = {
							assignVariableTypes = false,
							compositeLiteralFields = true,
							compositeLiteralTypes = false,
							constantValues = true,
							functionTypeParameters = false,
							parameterNames = true,
							rangeVariableTypes = false,
						},
					},
				},
			},
			html = {},
			jdtls = {},
			jsonls = {},
			rust_analyzer = {
				settings = {
					["rust-analyzer"] = {
						cargo = {
							allFeatures = true,
						},
						check = {
							command = "clippy",
						},
						completion = {
							fullFunctionSignatures = {
								enable = true,
							},
						},
						inlayHints = {
							bindingModeHints = { enable = true },
							chainingHints = { enable = true },
							closingBraceHints = { enable = true, minLines = 25 },
							closureCaptureHints = { enable = true },
							closureReturnTypeHints = { enable = "never" },
							discriminantHints = { enable = "always" },
							expressionAdjustmentHints = { enable = "always" },
							implicitDrops = { enable = true },
							lifetimeElisionHints = { enable = "never", useParameterNames = false },
							maxLength = 25,
							parameterHints = { enable = true },
							rangeExclusiveHints = { enable = true },
							reborrowHints = { enable = "always" },
							renderColons = true,
							typeHints = {
								enable = false,
								hideClosureInitialization = false,
								hideNamedConstructor = false,
							},
						},
					},
				},
			},
			tailwindcss = {},
			vtsls = {
				settings = {
					vtsls = {
						autoUseWorkspaceTsdk = true,
					},
					typescript = {
						inlayHints = {
							parameterNames = { enabled = "literals" },
							parameterTypes = { enabled = false },
							variableTypes = { enabled = false },
							propertyDeclarationTypes = { enabled = false },
							functionLikeReturnTypes = { enabled = false },
							enumMemberValues = { enabled = true },
						},
						suggest = {
							completeFunctionCalls = true,
						},
					},
					javascript = {
						inlayHints = {
							parameterNames = { enabled = "literals" },
							parameterTypes = { enabled = false },
							variableTypes = { enabled = false },
							propertyDeclarationTypes = { enabled = false },
							functionLikeReturnTypes = { enabled = false },
							enumMemberValues = { enabled = true },
						},
						suggest = {
							completeFunctionCalls = true,
						},
					},
				},
			},
			tinymist = { offset_encoding = "utf-8" },
			ty = {},
			lua_ls = {
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
						diagnostics = {
							globals = { "vim", "Snacks" },
							disable = { "missing-fields" },
						},
					},
				},
			},
		}

		local server_names = vim.tbl_keys(servers or {})

		-- Setup Mason for LSP and tool installation
		require("mason").setup()

		-- Configure tools to ensure installation (LSP servers + extra tools)
		local ensure_tools = {}
		vim.list_extend(ensure_tools, server_names)
		vim.list_extend(ensure_tools, {
			"biome",
			"eslint_d",
			"gofumpt",
			"goimports",
			"google-java-format",
			"prettier",
			"prettierd",
			"stylua", -- Lua formatter
		})

		if #vim.api.nvim_list_uis() > 0 then
			require("mason-tool-installer").setup({
				ensure_installed = ensure_tools,
			})
		end

		-- Configure each LSP server via vim.lsp.config (mason-lspconfig 2.0+ API)
		for server_name, server_settings in pairs(servers) do
			local config = vim.tbl_deep_extend("force", {}, server_settings)
			config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
			vim.lsp.config(server_name, config)
		end

		-- Setup mason-lspconfig (automatic_enable is on by default in v2.0+)
		require("mason-lspconfig").setup({
			ensure_installed = server_names,
		})

		-- Enable all configured LSP servers
		vim.lsp.enable(server_names)

		-- Manually trigger LSP for current buffer after config is registered.
		local bufnr = vim.api.nvim_get_current_buf()
		local ft = vim.bo[bufnr].filetype
		if ft and ft ~= "" then
			-- Re-trigger FileType to start LSP for current buffer
			vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
		end
	end,
}
