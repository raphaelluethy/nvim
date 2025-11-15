vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

vim.o.winborder = "rounded"

vim.opt.pumblend = 0
vim.opt.winblend = 0
-- [[ Setting options ]]
-- use Neovim nightly branch
-- See `:help vim.opt`

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
-- :set listchars=tab:▸\ ,space:·,trail:•,extends:>,precedes:<
vim.opt.listchars = {
	tab = "▸ ",
	trail = "•",
	space = "·",
	extends = ">",
	precedes = "<",
}

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

vim.opt.textwidth = 80
vim.opt.linebreak = true
vim.opt.colorcolumn = "80"

-- Enable automatic text wrapping at textwidth
-- vim.opt.formatoptions:append 't'

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.diagnostic.enable = true
vim.diagnostic.config({
	virtual_lines = false,
	virtual_text = true,
})

vim.keymap.set("n", "gh", vim.diagnostic.open_float, {
	desc = "Show diagnostic [E]rror messages",
})

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, {
	desc = "Open diagnostic [Q]uickfix list",
})

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", {
	desc = "Exit terminal mode",
})

vim.keymap.set("n", "<C-h>", "<C-w><C-h>", {
	desc = "Move focus to the left window",
})
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", {
	desc = "Move focus to the right window",
})
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", {
	desc = "Move focus to the lower window",
})
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", {
	desc = "Move focus to the upper window",
})

vim.keymap.set("n", "<leader>w", "<CMD>w<CR>", {
	desc = "[W]rite Buffer",
})

vim.keymap.set("n", "<leader>sv", "<CMD>vsplit<CR>", {
	desc = "[S]plit [V]ertically",
})

vim.keymap.set("n", "<leader>cn", "<CMD>cnext<CR>", {
	desc = "Next Quickfix Entry",
})
vim.keymap.set("n", "<leader>cp", "<CMD>cprev<CR>", {
	desc = "Previous Quickfix Entry",
})
vim.keymap.set("n", "<leader>co", "<CMD>copen<CR>", {
	desc = "Toggle Quickfix List",
})

-- move lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", {
	desc = "Move line down",
})
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", {
	desc = "Move line up",
})

-- reselect after indent
vim.keymap.set("v", "<", "<gv", {
	desc = "Reselect after indent",
})
vim.keymap.set("v", ">", ">gv", {
	desc = "Reselect after indent",
})

-- Redirect change operations to the blackhole to avoid spoiling 'y' register content
-- Shortcut to use blackhole register by default
vim.keymap.set("v", "c", '"_c')
vim.keymap.set("v", "C", '"_C')
vim.keymap.set("n", "c", '"_c')
vim.keymap.set("n", "C", '"_C')

-- -- remove defaults
vim.keymap.del("", "grr")
vim.keymap.del("", "gra")
vim.keymap.del("", "grn")
vim.keymap.del("", "gri")

-- vim.api.nvim_create_autocmd("TextYankPost", {
-- 	desc = "Highlight when yanking (copying) text",
-- 	group = vim.api.nvim_create_augroup("raphaelluethy-highlight-yank", {
-- 		clear = true,
-- 	}),
-- 	callback = function()
-- 		vim.highlight.on_yank()
-- 	end,
-- })

require("config.lazy")
