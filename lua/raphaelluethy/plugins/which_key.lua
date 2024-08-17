return {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    dependencies = {
        'nvim-tree/nvim-web-devicons',
    },
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },
    keys = {

        { '<leader>c',  group = '[C]ode' },
        { '<leader>c_', hidden = true },
        { '<leader>d',  group = '[D]ocument' },
        { '<leader>d_', hidden = true },
        { '<leader>r',  group = '[R]ename' },
        { '<leader>r_', hidden = true },
        { '<leader>s',  group = '[S]earch' },
        { '<leader>s_', hidden = true },
    },
}
