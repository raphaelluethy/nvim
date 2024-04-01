return {
    "lewis6991/gitsigns.nvim",
    config = function()
        require('gitsigns').setup({
            signcolumn = true -- Toggle with `:Gitsigns toggle_signs`
        })

        vim.keymap.set('n', '<leader>gh', ':Gitsigns blame_line<CR>', {})
    end
}
