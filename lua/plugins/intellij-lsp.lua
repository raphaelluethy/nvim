-- Java and Kotlin through JetBrains' IntelliJ language server, with their
-- official client (pre-alpha). The server bundle downloads on first start;
-- license with `:IntellijLspLicense`, check with `:checkhealth intellij-lsp`.
return {
	"JetBrains/intellij-lsp.nvim",
	-- Loaded at startup so opening nvim in a project starts the build import
	-- before any Java/Kotlin buffer exists; no server starts otherwise.
	lazy = false,
	dependencies = { "mfussenegger/nvim-dap" }, -- run and debug
	opts = {
		region = "europe",
		data_sharing = "none",
		progress = false,

		-- blink.cmp owns completion and the signature popup; the LspAttach
		-- autocmd in lsp.lua already highlights references.
		autotrigger = false,
		word_triggers = false,
		enter_accepts_completion = false,
		completeopt = false,
		signature_help = false,
		document_highlight = false,

		-- Its hierarchy maps would take <leader>ts (terminal split) and <leader>ci;
		-- use :IntellijLspTypeHierarchy / :IntellijLspCallHierarchy instead.
		keymaps = false,
		colorscheme = false, -- keep monokai-pro-zed
	},
	config = function(_, opts)
		-- The plugin's own debug maps (<leader>b, <leader>B, <leader>rd, <leader>dn,
		-- <leader>dq, and <leader>do as step *out*) shadow the global <leader>d
		-- layout in lua/plugins/dap.lua. IntelliJ debugging is a plain nvim-dap
		-- session, so the global db/dB/di/do/dO/dt/dl/du/dr maps drive it as-is;
		-- only starting a session and the IntelliJ panel need Java-buffer maps.
		-- client.lua looks this function up on every attach, so replacing it here
		-- takes effect for every IntelliJ buffer.
		local debug = require("intellij-lsp.debug")
		debug.set_keymaps = function(bufnr)
			local function map(lhs, rhs, desc, mode)
				vim.keymap.set(mode or "n", lhs, rhs, { buffer = bufnr, desc = desc })
			end
			local function debug_class()
				require("intellij-lsp.run").run_at_cursor(false)
			end
			-- nvim-dap has no Java configurations, so with no session running
			-- dap.continue() would only offer an empty picker; start IntelliJ's instead.
			local function continue()
				if require("dap").session() then
					require("dap").continue()
				else
					debug_class()
				end
			end

			map("<F5>", continue, "Debug: Continue/start (IntelliJ)")
			map("<leader>dc", continue, "Debug: Continue/start (IntelliJ)")
			map("<leader>dd", debug_class, "Debug: Debug the class at the cursor (IntelliJ)")
			map("<leader>de", debug.evaluate_at_cursor, "Debug: Evaluate (IntelliJ)", { "n", "x" })
			map("<leader>dw", debug.watch_at_cursor, "Debug: Watch expression (IntelliJ)", { "n", "x" })
			map("<leader>dv", debug.open, "Debug: IntelliJ panel (stack, locals, watches)")
		end

		require("intellij-lsp").setup(opts)
	end,
}
