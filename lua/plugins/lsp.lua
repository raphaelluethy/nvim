return {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} },
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		if vim.fn.exists(":LspInfo") == 0 then
			vim.api.nvim_create_user_command("LspInfo", function()
				vim.cmd("checkhealth vim.lsp")
			end, { desc = "Alias to :checkhealth vim.lsp" })
		end

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
				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame symbol", { "n", "x" })

				-- Hover sizes to its longest line by default, so long type
				-- unions span the whole screen; cap it.
				map("K", function()
					vim.lsp.buf.hover({ max_width = 90, max_height = 24 })
				end, "Hover documentation")

				-- Signature help (matching Zed: ctrl-s)
				map("<C-s>", vim.lsp.buf.signature_help, "Signature help")
				map("<C-s>", vim.lsp.buf.signature_help, "Signature help", "i")

				local client = vim.lsp.get_client_by_id(event.data.client_id)

				-- Document highlighting: highlights all references to symbol under cursor
				if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
					local highlight_augroup = vim.api.nvim_create_augroup("raphaelluethy-lsp-highlight", {
						clear = false,
					})

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

		local function disable_formatting(client)
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end

		-- Add an LSP by putting its nvim-lspconfig name in `ensure_lsps`.
		-- Mason installs it; mason-lspconfig enables it. No extra setup needed.
		-- Only add an entry to `servers` when you want extra settings.
		local ensure_lsps = {
			"biome",
			"clangd",
			"cssls",
			"emmet_language_server",
			"gopls",
			"html",
			"jdtls",
			"jsonls",
			"lua_ls",
			"oxlint",
			"rust_analyzer",
			"tailwindcss",
			"tinymist",
			"tsc",
			"ty",
			"vtsls",
		}

		-- Optional per-server overrides. Empty `{}` is never required.
		local servers = {
			-- Conform owns formatting (oxfmt → biome). Keep biome for diagnostics.
			biome = {
				on_attach = disable_formatting,
			},
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
			oxlint = {
				settings = {
					fixKind = "all",
				},
			},
			gopls = {
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
			-- TypeScript 7 (`tsc --lsp`). Complements vtsls; formatting stays in conform.
			tsc = {
				on_attach = disable_formatting,
			},
			vtsls = {
				on_attach = disable_formatting,
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

		for server_name, server_settings in pairs(servers) do
			vim.lsp.config(server_name, server_settings)
		end

		-- Formatters / linters (not LSPs). Install extra LSPs via ensure_lsps.
		local ensure_tools = {
			"biome",
			"gofumpt",
			"goimports",
			"google-java-format",
			"oxfmt",
			"prettier",
			"prettierd",
			"stylua",
		}

		if #vim.api.nvim_list_uis() > 0 then
			require("mason-tool-installer").setup({
				ensure_installed = ensure_tools,
			})
		end

		-- Mason installs these; mason-lspconfig enables them automatically.
		-- oxfmt has an LSP, but conform runs the CLI so we don't attach both.
		require("mason-lspconfig").setup({
			ensure_installed = ensure_lsps,
			automatic_enable = {
				exclude = { "oxfmt" },
			},
		})
	end,
}
