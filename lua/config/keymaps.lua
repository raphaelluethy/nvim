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
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, {
	desc = "Open diagnostic quickfix list",
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

-- Split keymaps (matching Zed: space s r/l/d/u)
vim.keymap.set("n", "<leader>sv", "<CMD>vsplit<CR>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>sh", "<CMD>split<CR>", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>sr", "<CMD>vsplit<CR>", { desc = "Split right" })
vim.keymap.set("n", "<leader>sl", "<CMD>aboveleft vsplit<CR>", { desc = "Split left" })
vim.keymap.set("n", "<leader>sd", "<CMD>split<CR>", { desc = "Split down" })
vim.keymap.set("n", "<leader>su", "<CMD>aboveleft split<CR>", { desc = "Split up" })
vim.keymap.set("n", "<leader>sc", "<CMD>close<CR>", { desc = "Close split" })

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
