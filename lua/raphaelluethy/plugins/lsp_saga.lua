return {
    'nvimdev/lspsaga.nvim',
    dependencies = {
        'nvim-treesitter/nvim-treesitter', -- optional
        'nvim-tree/nvim-web-devicons'      -- optional
    },
    config = function()
        require('lspsaga').setup({
            lightbulb = {
                enable = true,
                virtual_text = false
            }
        })
        vim.keymap.set('n', '<leader>lrn', '<CMD>Lspsaga rename <CR>', { desc = '[R]e[n]ame' })
        vim.keymap.set('n', '<leader>lrnp', '<CMD>Lspsaga rename ++project <CR>', { desc = '[R]e[n]ame' })
    end,
}
