return {
	"numerataz/ninetyfive.nvim",
	version = "*",
	config = function()
		-- Headless Neovim (agent sessions) has no UI and should not open a socket.
		-- setup() still has to run: the plugin auto-enables if setup was skipped.
		local has_ui = #vim.api.nvim_list_uis() > 0

		require("ninetyfive").setup({
			enable_on_startup = has_ui,
			-- Inline ghost text. Blink owns the menu; this is not an nvim-cmp source.
			use_cmp = false,
			-- Blink owns Tab / C-j. The plugin's defaults also bind C-h (backspace)
			-- and C-w (delete word) unconditionally, including in normal mode.
			mappings = {
				accept = false,
				accept_word = false,
				accept_line = false,
				reject = false,
			},
			-- "ask" opens a vim.ui.select (Telescope) during startup, before the UI is
			-- ready, so the picker can't be answered. Decide here instead: "on" | "off".
			indexing = {
				mode = "off",
			},
		})

		if not has_ui then
			return
		end

		-- The plugin renders whitespace-only suggestions (e.g. a lone "\n") as an
		-- empty virtual line under the cursor, and Tab would accept them invisibly.
		-- Treat them as no suggestion. Callers use the module tables, so patching
		-- them here covers websocket, SSE and the blink/Tab checks.
		local Completion = require("ninetyfive.completion")
		local suggestion = require("ninetyfive.suggestion")

		local function text_of(chunks)
			local parts = {}
			for _, item in ipairs(type(chunks) == "table" and chunks or {}) do
				if item == vim.NIL then
					break
				end
				parts[#parts + 1] = tostring(item)
			end
			return table.concat(parts)
		end

		local has_active = Completion.has_active_completion
		Completion.has_active_completion = function()
			local current = Completion.get()
			return has_active() and text_of(current.completion):find("%S") ~= nil
		end

		local show = suggestion.show
		suggestion.show = function(chunks)
			if not text_of(chunks):find("%S") then
				return suggestion.clear()
			end
			return show(chunks)
		end

		local function has_suggestion()
			return Completion.has_active_completion()
		end

		-- Same dismiss key as the old Supermaven clear. Falls through otherwise.
		vim.keymap.set("i", "<C-]>", function()
			if has_suggestion() then
				return "<Cmd>NinetyFiveReject<CR>"
			end
			return "<C-]>"
		end, { expr = true, silent = true, desc = "Dismiss NinetyFive suggestion" })

		-- Accept the next line. C-l in normal mode stays window navigation.
		vim.keymap.set("i", "<C-l>", function()
			if has_suggestion() then
				return "<Cmd>NinetyFiveAcceptLine<CR>"
			end
			return "<C-l>"
		end, { expr = true, silent = true, desc = "Accept next NinetyFive line" })
	end,
}
