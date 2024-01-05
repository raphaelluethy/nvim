-- clode buffer
vim.keymap.set('n', '<leader>bd', '<CMD>bd<CR>')
vim.keymap.set('n', '<leader>bn', '<CMD>bn<CR>')

-- search for buffers
vim.keymap.set('n', '<leader>bb', '<CMD>Telescope buffers<CR>')

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
vim.keymap.set("i", "jj", "<ESC>")

-- hover
-- vim.keymap.set("<C-h>", "<Cmd>lua vim.lsp.buf.hover()<CR>")

-- move buffer
vim.keymap.set("n","gn", ":bnext<cr>")
vim.keymap.set("n","gp", ":bprevious<cr>")