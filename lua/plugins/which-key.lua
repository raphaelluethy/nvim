return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
		delay = 200,
		icons = {
			mappings = vim.g.have_nerd_font,
			keys = vim.g.have_nerd_font and {} or {
				Up = "<Up> ",
				Down = "<Down> ",
				Left = "<Left> ",
				Right = "<Right> ",
				C = "<C-…> ",
				M = "<M-…> ",
				D = "<D-…> ",
				S = "<S-…> ",
				CR = "<CR> ",
				Esc = "<Esc> ",
				ScrollWheelDown = "<ScrollWheelDown> ",
				ScrollWheelUp = "<ScrollWheelUp> ",
				NL = "<NL> ",
				BS = "<BS> ",
				Space = "<Space> ",
				Tab = "<Tab> ",
				F1 = "<F1>",
				F2 = "<F2>",
				F3 = "<F3>",
				F4 = "<F4>",
				F5 = "<F5>",
				F6 = "<F6>",
				F7 = "<F7>",
				F8 = "<F8>",
				F9 = "<F9>",
				F10 = "<F10>",
				F11 = "<F11>",
				F12 = "<F12>",
			},
		},
		spec = {
			-- Leader groups
			{ "<leader>9", group = "99 AI", icon = "󰚩" },
			{ "<leader>c", group = "Code/Terminal", icon = "" },
			{ "<leader>d", group = "Document", icon = "󰈙" },
			{ "<leader>f", group = "Find (Telescope)", icon = "" },
			{ "<leader>g", group = "Git", icon = "" },
			{ "<leader>h", group = "Harpoon", icon = "󱡀" },
			{ "<leader>o", group = "Outline/Symbols", icon = "" },
			{ "<leader>r", group = "Rename", icon = "󰑕" },
			{ "<leader>s", group = "Split/Search", icon = "" },
			{ "<leader>t", group = "Toggle/Diagnostics", icon = "" },
			{ "<leader>u", group = "Undo", icon = "󰕌" },
			{ "<leader>w", group = "Write", icon = "󰆓" },
			{ "<leader>x", group = "Trouble", icon = "󰒡" },
			-- Navigation groups
			{ "]", group = "Next", icon = "" },
			{ "[", group = "Prev", icon = "" },
			-- Goto group
			{ "g", group = "Goto", icon = "󰈞" },
			-- Folds group
			{ "z", group = "Folds/View", icon = "" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps",
		},
	},
}
