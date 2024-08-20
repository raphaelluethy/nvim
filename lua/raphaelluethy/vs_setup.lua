-- Settings for when neovim is running inside of vscode 
vim.keymap.set('n', 'H', "<Cmd>lua require('vscode-neovim').call('workbench.action.previousEditor')<CR>", {
    desc = ''
})
vim.keymap.set('n', 'L', "<Cmd>lua require('vscode-neovim').call('workbench.action.nextEditor')<CR>", {
    desc = ''
})

-- <Cmd>lua require('vscode-neovim').call('editor.action.formatSelection')<CR>
vim.keymap.set('n', '<leader>w', "<Cmd>lua require('vscode-neovim').call('workbench.action.files.save')<CR>", {
    desc = ''
})
vim.keymap.set('n', '<leader>f', "<Cmd>lua require('vscode-neovim').call('editor.action.formatDocument')<CR>", {
    desc = ''
})

vim.keymap.set('n', '<leader>e', "<Cmd>lua require('vscode-neovim').call('workbench.action.quickOpen')<CR>", {
    desc = ''
})

vim.keymap.set('n', '<leader>sp', "<Cmd>lua require('vscode-neovim').call('workbench.action.quickOpen')<CR>", {
    desc = ''
})

vim.keymap.set('n', '<C-b>', "<Cmd>lua require('vscode-neovim').call('workbench.action.toggleSidebarVisibility')<CR>", {
    desc = ''
})
