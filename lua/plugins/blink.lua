-- Icon and highlight group for a menu item, from mini.icons.
local function mini_icon(ctx)
	if ctx.source_id == "copilot" then
		return ctx.kind_icon, "MiniIconsPurple"
	end
	local MiniIcons = require("mini.icons")
	if ctx.source_name == "Path" then
		local is_dir = ctx.item.data and ctx.item.data.type == "directory"
		return MiniIcons.get(is_dir and "directory" or "file", ctx.label)
	end
	return MiniIcons.get("lsp", ctx.kind)
end

local function toggle(var, label)
	return function()
		vim.g[var] = vim.g[var] == false
		require("blink.cmp").hide()
		vim.notify(label .. (vim.g[var] == false and " off" or " on"))
	end
end

return {
	"saghen/blink.cmp",
	version = "1.*",
	-- Loading on InsertEnter runs blink's setup inside that very event, so
	-- the insert session that loads it never gets a completion request.
	-- Blink defers its own setup; let it load at startup.
	lazy = false,
	dependencies = { "rafamadriz/friendly-snippets", "fang2hou/blink-copilot" },
	keys = {
		{ "<leader>uc", toggle("completion", "Completion"), desc = "Toggle completion" },
		{ "<leader>ua", toggle("copilot", "Copilot"), desc = "Toggle Copilot completions" },
	},
	opts = {
		-- <leader>uc turns the whole menu off, <leader>ua only Copilot.
		enabled = function()
			return vim.g.completion ~= false and vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
		end,
		-- Enter accepts the menu item. Tab jumps through snippets. C-j / C-k
		-- move through the menu.
		keymap = {
			preset = "enter",
			["<Tab>"] = { "snippet_forward", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
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
					-- Icons and colors from mini.icons, matching oil and telescope.
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
			default = { "lsp", "copilot", "path", "snippets", "buffer" },
			providers = {
				-- Copilot suggestions as menu items (copilot LSP, lua/plugins/lsp.lua).
				copilot = {
					name = "Copilot",
					module = "blink-copilot",
					async = true,
					enabled = function()
						return vim.g.copilot ~= false
					end,
					opts = { max_completions = 2, max_attempts = 3 },
				},
				-- Blink holds the menu up to 2s for LSP by default; show other
				-- sources sooner and merge slow LSP results in as they arrive.
				lsp = { timeout_ms = 150 },
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
	opts_extend = { "sources.default" },
}
