-- Neovim keeps showing an inline completion item after you type past the
-- position it was requested at, until the next (debounced) response arrives.
-- Its range still ends at the old cursor, so accepting it leaves the newly
-- typed characters behind (e.g. "foob" + "foobar" -> "foobarb"). Stretch the
-- range to the cursor when the typed text is still a prefix of the
-- suggestion, and clamp it to the line so a backspace can't push it out of
-- bounds.
local function fix_stale_range(item)
	if not item.range or type(item.insert_text) ~= "string" then
		return item
	end
	local buf = vim.api.nvim_get_current_buf()
	local sr, sc, er, ec = item.range:to_extmark()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	if row == er and col > ec then
		local typed = table.concat(vim.api.nvim_buf_get_text(buf, sr, sc, row, col, {}), "\n")
		if vim.startswith(item.insert_text, typed) then
			ec = col
		end
	end
	local line = vim.api.nvim_buf_get_lines(buf, er, er + 1, false)[1] or ""
	ec = math.min(ec, #line)

	item.range = vim.range.extmark(buf, sr, sc, er, ec)
	return item
end

return {
	"saghen/blink.cmp",
	version = "1.*",
	event = "InsertEnter",
	dependencies = { "rafamadriz/friendly-snippets" },
	opts = {
		-- Enter accepts the menu item. Tab: snippet jump, then Copilot next edit
		-- suggestion, then Copilot ghost text. C-j / C-k match the previous
		-- native popup bindings.
		keymap = {
			preset = "enter",
			["<Tab>"] = {
				"snippet_forward",
				function()
					return require("sidekick").nes_jump_or_apply()
				end,
				function()
					return vim.lsp.inline_completion.get({ on_accept = fix_stale_range })
				end,
				"fallback",
			},
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },
			["<C-c>"] = { "hide", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<CR>"] = { "accept", "fallback" },
		},
		appearance = {
			nerd_font_variant = "mono",
		},
		completion = {
			list = {
				selection = { preselect = false, auto_insert = false },
			},
			menu = {
				border = "rounded",
				draw = {
					columns = {
						{ "kind_icon", "label", "label_description", gap = 1 },
						{ "kind" },
					},
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
				window = { border = "rounded" },
			},
			ghost_text = { enabled = false },
		},
		signature = {
			enabled = true,
			window = { border = "rounded" },
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			providers = {
				-- Blink holds the menu up to 2s for LSP by default; show other
				-- sources sooner and merge slow LSP results in as they arrive.
				lsp = { timeout_ms = 150 },
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
	opts_extend = { "sources.default" },
}
