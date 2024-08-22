return {
    dir = '~/.config/nvim/lua/raphaelluethy/plugins/custom/summary',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        local summary = require('summary').setup {
            branch = 'develop',
        }
        vim.keymap.set('n', '<leader>gs', summary.generate_summary, { desc = '[G]it [S]ummary' })
    end,
}
