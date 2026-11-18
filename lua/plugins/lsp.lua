local function lsp_picker(scope)
	return function()
		require("mini.extra").pickers.lsp({ scope = scope })
	end
end

return {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	version = "*",
	config = function()
		if vim.fn.exists(":LspInfo") == 0 then
			vim.api.nvim_create_user_command("LspInfo", function()
				vim.cmd("checkhealth vim.lsp")
			end, { desc = "Alias to :checkhealth vim.lsp" })
		end

		-- Copilot is the only configured server that offers inline completions.
		vim.lsp.inline_completion.enable(true)
		vim.keymap.set("n", "<leader>ua", function()
			local enabled = not vim.lsp.is_enabled("copilot")
			vim.lsp.enable("copilot", enabled)
			vim.notify(enabled and "Copilot on" or "Copilot off")
		end, { desc = "Toggle Copilot server" })

		local highlight_method = vim.lsp.protocol.Methods.textDocument_documentHighlight
		local highlight_group = vim.api.nvim_create_augroup("raphaelluethy-lsp-highlight", { clear = true })

		local function setup_highlights(buf)
			local opts = { buffer = buf, group = highlight_group }
			if #vim.api.nvim_get_autocmds(opts) > 0 then
				return
			end

			local function on(events, callback)
				vim.api.nvim_create_autocmd(events, { buffer = buf, group = highlight_group, callback = callback })
			end

			-- document_highlight() already dispatches to every supporting client.
			on({ "CursorHold", "CursorHoldI" }, function()
				if vim.api.nvim_buf_line_count(buf) <= 3000 then
					vim.lsp.buf.document_highlight()
				end
			end)
			on({ "CursorMoved", "CursorMovedI" }, function()
				vim.lsp.util.buf_clear_references(buf)
			end)
			on("LspDetach", function(event)
				-- LspDetach runs before Neovim removes this client from the buffer.
				for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, method = highlight_method })) do
					if client.id ~= event.data.client_id then
						return
					end
				end
				vim.lsp.util.buf_clear_references(buf)
				vim.api.nvim_clear_autocmds(opts)
			end)
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
				map("gd", vim.lsp.buf.definition, "Goto definition")
				map("gr", lsp_picker("references"), "Goto references")
				map("gI", lsp_picker("implementation"), "Goto implementation")
				map("gD", vim.lsp.buf.declaration, "Goto declaration")
				map("gt", lsp_picker("type_definition"), "Goto type definition")

				-- Symbol search keymaps (matching Zed: space o)
				map("<leader>o", lsp_picker("document_symbol"), "Document symbols (Outline)")
				map("<leader>ss", lsp_picker("workspace_symbol_live"), "Workspace symbols")

				-- Code actions
				map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
				map("<leader>cr", vim.lsp.buf.rename, "Rename symbol", { "n", "x" })

				-- Hover sizes to its longest line by default, so long type
				-- unions span the whole screen; cap it.
				map("K", function()
					vim.lsp.buf.hover({ max_width = 90, max_height = 24 })
				end, "Hover documentation")

				local client = vim.lsp.get_client_by_id(event.data.client_id)

				if client and client:supports_method(highlight_method, event.buf) then
					setup_highlights(event.buf)
				end

				-- Inlay hints: enable by default and add toggle keymap if supported
				if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
					vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
					map("<leader>uh", function()
						local bufnr = event.buf
						vim.lsp.inlay_hint.enable(
							not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
							{ bufnr = bufnr }
						)
					end, "Toggle inlay hints")
				end
			end,
		})

		local function disable_formatting(client)
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end

		-- Add an LSP by putting its nvim-lspconfig name in lua/config/servers.lua.
		-- Mason installs it and it is enabled below. No extra setup needed.
		-- Only add an entry to `servers` when you want extra settings.

		-- Optional per-server overrides. Empty `{}` is never required.
		local servers = {
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
			-- TypeScript handles language features; Oxfmt owns formatting.
			tsc = {
				on_attach = disable_formatting,
				settings = {
					["js/ts"] = {
						-- Hide type hints like Zed; keep parameter names and enum values.
						inlayHints = {
							parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = true },
							parameterTypes = { enabled = false },
							variableTypes = { enabled = false },
							propertyDeclarationTypes = { enabled = false },
							functionLikeReturnTypes = { enabled = false },
							enumMemberValues = { enabled = true },
						},
					},
				},
			},
			tinymist = { offset_encoding = "utf-8" },
			-- Copilot is inline-only; never offer it in Blink's LSP menu.
			copilot = {
				on_init = function(client)
					client.server_capabilities.completionProvider = nil
				end,
				settings = { telemetry = { telemetryLevel = "off" } },
				-- Do not attach to secrets files.
				root_dir = function(bufnr, on_dir)
					local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
					if name == "" or name:match("^%.env") or name:match("%.pem$") or name:match("%.key$") then
						return
					end
					on_dir(vim.fs.root(bufnr, ".git") or vim.fn.getcwd())
				end,
			},
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

		-- Mason installs these (lua/plugins/mason.lua); enable them here so the
		-- LSP starts even before Mason has loaded. Servers not in this list
		-- (eslint, ts_ls, vtsls, jdtls, ...) stay off even if installed. Java
		-- and Kotlin go through intellij-lsp.nvim (lua/plugins/intellij-lsp.lua).
		vim.lsp.enable(require("config.servers").lsp_names())
	end,
}
