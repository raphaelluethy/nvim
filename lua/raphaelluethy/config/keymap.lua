-- close buffer
vim.keymap.set('n', '<leader>bd', '<CMD>bd<CR>')
vim.keymap.set('n', '<leader>bn', '<CMD>bn<CR>')

-- move lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- up and down
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- find tokens
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- exit insert mode
vim.keymap.set("i", "jk", "<ESC>")

-- move buffer
vim.keymap.set("n", "gn", ":bnext<cr>")
vim.keymap.set("n", "gp", ":bprevious<cr>")

-- reselect after indent
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Redirect change operations to the blackhole to avoid spoiling 'y' register content
-- Shortcut to use blackhole register by default
vim.keymap.set('v', 'c', '"_c')
vim.keymap.set('v', 'C', '"_C')
vim.keymap.set('n', 'c', '"_c')
vim.keymap.set('n', 'C', '"_C')
