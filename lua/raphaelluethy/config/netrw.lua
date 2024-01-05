-- vim.keymap.set('n', '<leader>b', '<CMD>Explore %:p:h<CR>')
vim.keymap.set('n', '<C-b>', function()
    if vim.bo.filetype == 'netrw' then
        vim.cmd('bd')
    else
        vim.cmd('e . | :Ex')
    end
end)
vim.keymap.set('n', '<leader>b', function()
    if vim.bo.filetype == 'netrw' then
        vim.cmd('bd')
    else
        vim.cmd('e . | :Ex')
    end
end)-- setup netrw

vim.g.netrw_fastbrowse = 0
vim.g.netrw_liststyle = 3