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

        -- keymaps with whichkey
        local wk = require("which-key")
        wk.register({
            ["<leader>?"] = { builtin.oldfiles, "Find recently opened files" },
            ["<leader>ff"] = {builtin.find_files, "Find files"},
            ["<leader>fa"] = {function()
                builtin.find_files({
                    hidden = true,
                    no_ignore = true
                })
            end, "Find all files"},
            ["<leader>fg"] = {builtin.live_grep, "Find in files"},
            ["<leader>fb"] = {builtin.buffers, "Find buffers"},
            ["<leader>fh"] = {builtin.help_tags, "Find help tags"},
            ["<leader>fs"] = {function()
                builtin.lsp_document_symbols({
                    symbols = {'Function', 'Method'}
                })
            end, "Find symbols"},
            ["<leader><leader>"] = {builtin.buffers, "Find open Buffers"},
            ["<C-p>"] = {function()
                builtin.git_files({
                    hidden = true,
                })
            end, "Find git files"},
            ["<leader>sd"] = {builtin.diagnostics, "Find diagnostics"},
            ["<leader>sw"] = {builtin.grep_string, "Find current word"},
            ["<leader>sg"] = {builtin.live_grep, "Find by grep"},
            ["<leader>sa"] = {function()
                builtin.find_files({
                    hidden = true,
                    no_ignore = true
                })
            end, "Find all files"},
            ["<leader>sh"] = {builtin.help_tags, "Find help tags"},
            ["<leader>sf"] = { function()
                builtin.find_files({
                    hidden = true,
                })
            end, "Find files"},
            ["<leader>gf"] = {builtin.git_files, "Find git files"},
        })
    end
}
