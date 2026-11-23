-- Icon and highlight group for a menu item, from mini.icons.
local function mini_icon(ctx)
	local MiniIcons = require("mini.icons")
	if ctx.source_name == "Path" then
		local is_dir = ctx.item.data and ctx.item.data.type == "directory"
		return MiniIcons.get(is_dir and "directory" or "file", ctx.label)
	end
	return MiniIcons.get("lsp", ctx.kind)
end

local function toggle_completion()
	vim.g.completion = vim.g.completion == false
	require("blink.cmp").hide()
	vim.notify(vim.g.completion and "Completion menu on" or "Completion menu off")
end

local eager = true

local function toggle_copilot_acceptance()
	eager = not eager
	vim.notify(eager and "Copilot eager: Tab to accept" or "Copilot lazy: Option+Tab to accept")
end

local function accept_inline_completion(cmp)
	if not vim.lsp.inline_completion.get() then
		return false
	end
	cmp.hide()
	return true
end

local function accept_completion()
	local cmp = require("blink.cmp")
	-- Opt+Tab accepts the selected item, then ghost text (lazy mode only), then the first item.
	if cmp.accept() or (not eager and accept_inline_completion(cmp)) then
		return
	end
	cmp.select_and_accept()
end

return {
	"saghen/blink.cmp",
	version = "1.*",
	-- Loading on InsertEnter runs blink's setup inside that very event, so
	-- the insert session that loads it never gets a completion request.
	-- Blink defers its own setup; let it load at startup.
	lazy = false,
	dependencies = { "rafamadriz/friendly-snippets" },
	init = function()
		-- Blink's Tab jumps through snippets first, then falls back to this mapping.
		-- Keep it outside Blink so it also works when the completion menu is disabled.
		vim.keymap.set("i", "<Tab>", function()
			if eager and accept_inline_completion(require("blink.cmp")) then
				return ""
			end
			return "<Tab>"
		end, { expr = true, desc = "Accept eager Copilot suggestion or insert Tab" })
	end,
	keys = {
		{ "<leader>uc", toggle_completion, desc = "Toggle completion menu" },
		{ "<leader>ue", toggle_copilot_acceptance, desc = "Toggle eager/lazy Copilot acceptance" },
		{ "<M-Tab>", accept_completion, mode = "i", desc = "Accept completion" },
	},
	opts = {
		enabled = function()
			return vim.g.completion ~= false and vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
		end,
		-- Enter inserts a newline. Tab jumps through snippets. C-j / C-k move through the menu.
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
			["<CR>"] = false,
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
					-- Icons and colors from mini.icons, matching oil and the Snacks picker.
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
