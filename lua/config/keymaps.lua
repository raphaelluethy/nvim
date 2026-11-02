-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("n", "gh", vim.diagnostic.open_float, {
	desc = "Show diagnostic error messages",
})

-- Diagnostic keymaps (matching Zed: ] d, [ d, space t n/p)
local function diagnostic_float(diagnostic, bufnr)
	if diagnostic then
		vim.diagnostic.open_float(bufnr, { scope = "cursor", focus = false })
	end
end

local function next_diagnostic()
	vim.diagnostic.jump({ count = 1, on_jump = diagnostic_float })
end

local function prev_diagnostic()
	vim.diagnostic.jump({ count = -1, on_jump = diagnostic_float })
end

vim.keymap.set("n", "]d", next_diagnostic, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", prev_diagnostic, { desc = "Prev diagnostic" })
vim.keymap.set("n", "<leader>tn", next_diagnostic, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>tp", prev_diagnostic, { desc = "Prev diagnostic" })
vim.keymap.set("n", "<leader>xd", vim.diagnostic.setloclist, {
	desc = "Diagnostics to location list",
})

vim.keymap.set("n", "<leader>u", function()
	vim.cmd("packadd nvim.undotree")
	vim.cmd("Undotree")
end, { desc = "Toggle Undotree" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", {
	desc = "Exit terminal mode",
})

-- Terminals (panels.nvim): Rex panes / tabs or Neovim splits / tabs per the
-- "terminal" switch in lua/plugins/panels.lua. Also :Panels term [where] [cmd].
local function term(opts)
	return function()
		require("panels").term(opts)
	end
end
-- One toggled terminal at the bottom (matching Zed: alt-t, space c t).
vim.keymap.set("n", "<A-t>", term({ id = "term:main", where = "split" }), { desc = "Toggle terminal" })
vim.keymap.set("n", "<leader>ct", term({ id = "term:main", where = "split" }), { desc = "Toggle terminal" })
vim.keymap.set("t", "<A-t>", "<C-\\><C-n>", { desc = "Exit terminal" })
-- New terminals, like :vsplit | terminal etc.
vim.keymap.set("n", "<leader>tv", term({ where = "vsplit" }), { desc = "Terminal: vertical split" })
vim.keymap.set("n", "<leader>ts", term({ where = "split" }), { desc = "Terminal: horizontal split" })
vim.keymap.set("n", "<leader>tT", term({ where = "tab" }), { desc = "Terminal: tab" })
vim.keymap.set("n", "<leader>tf", term({ where = "float" }), { desc = "Terminal: float" })

-- Window navigation: also into/out of floating panels, and at Neovim's edge
-- on into the neighbouring Rex pane (panels.nvim). Terminal mode too, so
-- agent terminals are left the same way.
for key, name in pairs({ h = "left", j = "lower", k = "upper", l = "right" }) do
	vim.keymap.set({ "n", "t" }, "<C-" .. key .. ">", function()
		require("panels").navigate(key)
	end, { desc = "Move focus to the " .. name .. " window" })
end

vim.keymap.set("n", "<leader>w", "<CMD>w<CR>", {
	desc = "[W]rite Buffer",
})

-- Splits: <leader>v (<leader>s is Telescope search, <leader>w is write)
vim.keymap.set("n", "<leader>vv", "<CMD>vsplit<CR>", { desc = "Split right" })
vim.keymap.set("n", "<leader>vr", "<CMD>vsplit<CR>", { desc = "Split right" })
vim.keymap.set("n", "<leader>vl", "<CMD>aboveleft vsplit<CR>", { desc = "Split left" })
vim.keymap.set("n", "<leader>vs", "<CMD>split<CR>", { desc = "Split down" })
vim.keymap.set("n", "<leader>vd", "<CMD>split<CR>", { desc = "Split down" })
vim.keymap.set("n", "<leader>vu", "<CMD>aboveleft split<CR>", { desc = "Split up" })
vim.keymap.set("n", "<leader>vc", "<CMD>close<CR>", { desc = "Close split" })
vim.keymap.set("n", "<leader>vo", "<CMD>only<CR>", { desc = "Close other splits" })

-- Quickfix / location list: <leader>x (<leader>c is code & agents)
vim.keymap.set("n", "]q", "<CMD>cnext<CR>", { desc = "Next quickfix entry" })
vim.keymap.set("n", "[q", "<CMD>cprev<CR>", { desc = "Previous quickfix entry" })
vim.keymap.set("n", "<leader>xq", function()
	local open = vim.fn.getqflist({ winid = 0 }).winid ~= 0
	vim.cmd(open and "cclose" or "copen")
end, { desc = "Toggle quickfix list" })
vim.keymap.set("n", "<leader>xl", function()
	local open = vim.fn.getloclist(0, { winid = 0 }).winid ~= 0
	vim.cmd(open and "lclose" or "lopen")
end, { desc = "Toggle location list" })

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

-- Remove defaults in favor of the LSP mappings in lua/plugins/lsp.lua.
vim.keymap.del("", "grr")
vim.keymap.del("", "gra")
vim.keymap.del("", "grn")
vim.keymap.del("", "gri")
