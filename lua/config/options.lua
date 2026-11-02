-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- mise (and similar version managers) set GOBIN to GOROOT/bin. Mason's Go
-- installer then writes gopls/gofumpt/goimports there instead of its staging
-- dir, and fails with: Tried to link bin "gopls" to non-existent target "gopls".
vim.env.GOBIN = nil

vim.o.winborder = "rounded"

vim.opt.pumblend = 0
vim.opt.winblend = 0

-- [[ Setting options ]]
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

-- Save undo history
vim.opt.undofile = true
local undodir = vim.fn.stdpath("config") .. "/.undodir"
vim.fn.mkdir(undodir, "p")
vim.opt.undodir = undodir

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = {
	tab = "▸ ",
	trail = "•",
	space = "·",
	extends = ">",
	precedes = "<",
}

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Block cursor in insert mode too: Rex can't thicken the bar cursor yet
-- (https://discord.com/channels/1546797889009881158/1547761400208687206)
vim.opt.guicursor = "n-v-c-sm-i-ci-ve:block,r-cr-o:hor20,t:block-blinkon500-blinkoff500-TermCursor"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

vim.opt.textwidth = 80
vim.opt.linebreak = true
vim.opt.colorcolumn = "120"

vim.opt.laststatus = 3

-- No empty cmdline row below the statusline: the cmdline only appears while
-- typing. ui2 (experimental in 0.12) shows messages in a floating window
-- instead of the hidden cmdline, without hit-enter prompts; g< opens them.
vim.opt.cmdheight = 0
require("vim._core.ui2").enable({ msg = { targets = "msg" } })

vim.opt.termguicolors = true

vim.diagnostic.config({
	virtual_lines = false,
	virtual_text = true,
})
