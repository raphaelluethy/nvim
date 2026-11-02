-- Icon and highlight group for a menu item, from mini.icons.
local function mini_icon(ctx)
	local MiniIcons = require("mini.icons")
	if ctx.source_name == "Path" then
		local is_dir = ctx.item.data and ctx.item.data.type == "directory"
		return MiniIcons.get(is_dir and "directory" or "file", ctx.label)
	end
	return MiniIcons.get("lsp", ctx.kind)
end

return {
	"saghen/blink.cmp",
	version = "1.*",
	-- Loading on InsertEnter runs blink's setup inside that very event, so
	-- the insert session that loads it never gets a completion request.
	-- Blink defers its own setup; let it load at startup.
	lazy = false,
	dependencies = { "rafamadriz/friendly-snippets" },
	opts = {
		-- Enter accepts the menu item. Tab: snippet jump, then NinetyFive ghost
		-- text. C-j accepts the next suggested word when one is showing, and
		-- otherwise moves the menu. C-k matches the previous popup binding.
		keymap = {
			preset = "enter",
			["<Tab>"] = {
				"snippet_forward",
				function()
					local ok, completion = pcall(require, "ninetyfive.completion")
					if ok and completion.has_active_completion() then
						return vim.keycode("<Cmd>NinetyFiveAccept<CR>")
					end
				end,
				"fallback",
			},
			["<C-j>"] = {
				function()
					local ok, completion = pcall(require, "ninetyfive.completion")
					if ok and completion.has_active_completion() then
						return vim.keycode("<Cmd>NinetyFiveAcceptWord<CR>")
					end
				end,
				"select_next",
				"fallback",
			},
			["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },
			["<C-c>"] = { "hide", "fallback" },
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
					-- Icons and colors from mini.icons, matching oil/nvim-tree/telescope.
					-- Path completions get file/directory icons instead of the kind.
					components = {
						kind_icon = {
							text = function(ctx)
								return mini_icon(ctx) .. ctx.icon_gap
							end,
							highlight = function(ctx)
								return select(2, mini_icon(ctx))
							end,
						},
						kind = {
							highlight = function(ctx)
								return select(2, mini_icon(ctx))
							end,
						},
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
