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
-- vim.opt.wrap = true
-- vim.opt.linebreak = true
-- vim.opt.breakindent = true
--
-- Save undo history
vim.opt.undofile = true
if vim.fn.has("persistent_undo") == 1 then
	vim.opt.undodir = vim.fn.expand("~/.config/nvim/.undodir")
end

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

vim.opt.laststatus = 3

vim.opt.termguicolors = true

-- Enable automatic text wrapping at textwidth
-- vim.opt.formatoptions:append 't'

vim.diagnostic.config({
	virtual_lines = false,
	virtual_text = true,
})
