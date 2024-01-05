return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        local builtin = require('telescope.builtin')
        -- vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
        -- vim.keymap.set('n', '<leader>fa', function()
        --     builtin.find_files({
        --         hidden = true,
        --         no_ignore = true
        --     })
        -- end, {})
        -- vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
        -- vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
        -- vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
        -- vim.keymap.set('n', '<leader>fs', function()
        --     builtin.lsp_document_symbols({
        --         symbols = {'Function', 'Method'}
        --     })
        -- end, {})
        -- vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
        -- Enable telescope fzf native, if installed
        require('telescope').setup({
            defaults = {
                color_devicons = true
            }
        })

        pcall(require('telescope').load_extension, 'fzf')

        -- See `:help telescope.builtin`
        vim.keymap.set('n', '<leader>?', builtin.oldfiles, {
            desc = '[?] Find recently opened files'
        })
        vim.keymap.set('n', '<leader><space>', builtin.buffers, {
            desc = '[ ] Find existing buffers'
        })
        vim.keymap.set('n', '<leader>fz', function()
            -- You can pass additional configuration to telescope to change theme, layout, etc.
            builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                winblend = 10,
                previewer = false
            })
        end, {
            desc = '[/] Fuzzily search in current buffer'
        })

        vim.keymap.set('n', '<leader>gf', builtin.git_files, {
            desc = 'Search [G]it [F]iles'
        })
        vim.keymap.set('n', '<leader>sf', builtin.find_files, {
            desc = '[S]earch [F]iles'
        })
        vim.keymap.set('n', '<leader>sa', function()
            builtin.find_files({
                hidden = true,
                no_ignore = true
            })
        end, {
            desc = '[S]earch [A]ll Files'
        })
        vim.keymap.set('n', '<leader>sh', builtin.help_tags, {
            desc = '[S]earch [H]elp'
        })
        vim.keymap.set('n', '<leader>sw', builtin.grep_string, {
            desc = '[S]earch current [W]ord'
        })
        vim.keymap.set('n', '<leader>sg', builtin.live_grep, {
            desc = '[S]earch by [G]rep'
        })
        vim.keymap.set('n', '<leader>sd', builtin.diagnostics, {
            desc = '[S]earch [D]iagnostics'
        })
        vim.keymap.set('n', '<C-p>', function()
            builtin.git_files({
                hidden = true,
            })
        end, {})
    end
}
