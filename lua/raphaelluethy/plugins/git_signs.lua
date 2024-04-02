return { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    config = function()
        require('gitsigns').setup({
            signs = {
                add = { text = '+' },
                change = { text = '~' },
                delete = { text = '_' },
                topdelete = { text = '‾' },
                changedelete = { text = '~' },
            },
        })
        vim.keymap.set('n', '<leader>gb', '<CMD> Gitsigns blame_line <CR>', { desc = '[G]it [B]lame' })
    end
}
