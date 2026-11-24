-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- mise (and similar version managers) set GOBIN to GOROOT/bin. Mason's Go
-- installer then writes gopls/gofumpt/goimports there instead of its staging
-- dir, and fails with: Tried to link bin "gopls" to non-existent target "gopls".
vim.env.GOBIN = nil

-- Mason loads lazily (lua/plugins/mason.lua), so put its bin dir on PATH here
-- for language servers that start before it is loaded.
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if not vim.env.PATH:find(mason_bin, 1, true) then
	vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
end

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
vim.opt.list = false
vim.opt.listchars = {
	tab = "▸ ",
	trail = "•",
	space = "·",
	extends = ">",
	precedes = "<",
}
require("config.selection_whitespace")

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

-- Keep the default 1-line cmdline for routine messages (bufwrite, undo, yank,
-- ...) so they stay single-line and never overlap code; ui2 still shows
-- errors, warnings, notifications (echomsg) and progress as toasts, and g<
-- opens message history without hit-enter prompts.
vim.opt.cmdheight = 1
require("vim._core.ui2").enable({
	msg = {
		targets = {
			default = "cmd",
			emsg = "msg",
			echoerr = "msg",
			lua_error = "msg",
			rpc_error = "msg",
			shell_err = "msg",
			wmsg = "msg",
			echomsg = "msg",
			progress = "msg",
		},
	},
})

vim.opt.termguicolors = true

local severity = vim.diagnostic.severity
vim.diagnostic.config({
	severity_sort = true,
	virtual_lines = false,
	-- Only the cursor line gets inline text; the rest stay as signs.
	virtual_text = { current_line = true },
	signs = {
		text = {
			[severity.ERROR] = "●",
			[severity.WARN] = "●",
			[severity.INFO] = "●",
			[severity.HINT] = "●",
		},
	},
})

-- Folds from tree-sitter; open everything by default, `zc`/`zM` to fold.
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldtext = ""
vim.o.foldlevel = 99

-- Per-project overrides in `.nvim.lua` (searched up to $HOME, gated by
-- `:trust`). Use it e.g. for `vim.lsp.config("gopls", { settings = ... })`.
vim.o.exrc = true
