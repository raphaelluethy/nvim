-- Keymap popup: press <leader> (or any prefix) and wait, or <leader>? for the
-- current buffer's maps. Group names below label the prefixes; every mapping's
-- own `desc` provides the entry text.
return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
		delay = 250,
		icons = { mappings = false },
		spec = {
			{ "<leader>c", group = "Code & agents" },
			{ "<leader>c", group = "Code & agents", mode = "v" },
			{ "<leader>d", group = "Debug" },
			{ "<leader>f", group = "File" },
			{ "<leader>g", group = "Git" },
			{ "<leader>h", group = "Git hunk" },
			{ "<leader>j", group = "Java & agent tasks" },
			{ "<leader>j", group = "Agent tasks", mode = "v" },
			{ "<leader>m", group = "Review comments" },
			{ "<leader>m", group = "Review comments", mode = "v" },
			{ "<leader>M", group = "Merge conflict (codediff)" },
			{ "<leader>r", group = "Refactor" },
			{ "<leader>s", group = "Search" },
			{ "<leader>t", group = "Toggle / diagnostics" },
			{ "<leader>v", group = "Split" },
			{ "<leader>w", group = "Write / workspace" },
			{ "<leader>x", group = "Quickfix / lists" },
			{ "]", group = "Next" },
			{ "[", group = "Previous" },
			{ "g", group = "Goto" },
			{ "<leader>e", desc = "Harpoon menu" },
			{ "<leader>a", desc = "Harpoon add file" },
			{ "<leader>o", desc = "Document symbols" },
			{ "<leader>u", desc = "Undotree" },
			{ "<leader>/", desc = "Search in buffer" },
			{ "<leader><leader>", desc = "Buffers" },
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
