-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("n", "gh", vim.diagnostic.open_float, {
	desc = "Show diagnostic error messages",
})

-- Diagnostic keymaps (matching Zed: ] d, [ d, space t n/p)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set("n", "<leader>tn", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>tp", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
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

-- Terminal toggle (matching Zed: alt-t, space c t)
vim.keymap.set("n", "<A-t>", "<CMD>terminal<CR>", { desc = "Open terminal" })
vim.keymap.set("n", "<leader>ct", "<CMD>terminal<CR>", { desc = "Open terminal" })
vim.keymap.set("t", "<A-t>", "<C-\\><C-n>", { desc = "Exit terminal" })

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
