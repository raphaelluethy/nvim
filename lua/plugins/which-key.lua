-- Keymap popup: press <leader> (or any prefix) and wait, or <leader>? for the
-- current buffer's maps. Group names below label the prefixes; every mapping's
-- own `desc` provides the entry text. Icons come from mini.icons.
local function icon(cp, color)
	return { icon = cp, color = color }
end

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
		delay = 250,
		spec = {
			{ "<leader>a", group = "Agents", icon = icon("\u{F06A9}", "purple"), mode = { "n", "x" } },
			{ "<leader>c", group = "Code", icon = icon("\u{F121}", "cyan"), mode = { "n", "x" } },
			{ "<leader>d", group = "Debug", icon = icon("\u{F188}", "red") },
			{ "<leader>f", group = "File", icon = icon("\u{F0645}", "grey") },
			{ "<leader>g", group = "Git", icon = icon("\u{F02A2}", "orange") },
			{ "<leader>h", group = "Hunks & harpoon", icon = icon("\u{F02A2}", "orange"), mode = { "n", "x" } },
			{ "<leader>m", group = "Review comments", icon = icon("\u{F075}", "orange"), mode = { "n", "x" } },
			{ "<leader>M", group = "Merge conflict", icon = icon("\u{E727}", "orange") },
			{ "<leader>s", group = "Search", icon = icon("\u{F0349}", "yellow") },
			{ "<leader>t", group = "Terminal", icon = icon("\u{F120}", "green") },
			{ "<leader>u", group = "UI toggles", icon = icon("\u{F0521}", "cyan") },
			{ "<leader>v", group = "Splits", icon = icon("\u{F0DB}", "green") },
			{ "<leader>x", group = "Diagnostics & lists", icon = icon("\u{F0279}", "red") },
			{ "<leader>9", group = "99", icon = icon("\u{F0E7}", "purple"), mode = { "n", "x" } },
			{ "]", group = "Next" },
			{ "[", group = "Previous" },
			{ "g", group = "Goto" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer-local keymaps",
		},
	},
}
