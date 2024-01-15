return {
    "mbbill/undotree",
    config = function()
        -- right and wide bottom
        vim.g['undotree_WindowLayout'] = 4
        vim.g['undotree_SplitWidth'] = 30
        -- show shorthand date indicators
        vim.g['undotree_ShortIndicators'] = 1

        -- keymap
        vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
    end
}
