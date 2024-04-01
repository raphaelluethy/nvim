return {
    'romgrk/barbar.nvim',
    dependencies = {
        'lewis6991/gitsigns.nvim',     -- OPTIONAL: for git status
        'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
    },
    init = function() vim.g.barbar_auto_setup = false end,
    opts = {
        -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
        -- animation = true,
        -- insert_at_start = true,
        -- …etc.
        auto_hide = true,
    },
    version = '^1.0.0', -- optional: only update when a new 1.x version is released
    config = function()
        require('barbar').setup()
        local wk = require('which-key')
        wk.register({
            ['<leader>1'] = { ':BufferGoto 1<CR>', 'Go to buffer 1' },
            ['<leader>2'] = { ':BufferGoto 2<CR>', 'Go to buffer 2' },
            ['<leader>3'] = { ':BufferGoto 3<CR>', 'Go to buffer 3' },
            ['<leader>4'] = { ':BufferGoto 4<CR>', 'Go to buffer 4' },
            ['<leader>5'] = { ':BufferGoto 5<CR>', 'Go to buffer 5' },
            ['<leader>6'] = { ':BufferGoto 6<CR>', 'Go to buffer 6' },
            ['<leader>7'] = { ':BufferGoto 7<CR>', 'Go to buffer 7' },
            ['<leader>8'] = { ':BufferGoto 8<CR>', 'Go to buffer 8' },
            ['<leader>9'] = { ':BufferGoto 9<CR>', 'Go to buffer 9' },
            ['<leader>0'] = { ':BufferLast<CR>', 'Go to last buffer' },
            ['<leader>q'] = { ':BufferClose<CR>', 'Close buffer' },
            ['<leader>Q'] = { ':BufferCloseAllButCurrent<CR>', 'Close all but current buffer' },
            ['<leader>h'] = { ':BufferPrevious<CR>', 'Previous buffer' },
            ['<leader>l'] = { ':BufferNext<CR>', 'Next buffer' },
            ['<leader>o'] = { ':BufferPick<CR>', 'Pick buffer' },
        })
    end,
}
