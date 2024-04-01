return {
    "nvimdev/lspsaga.nvim",
    config = function()
        require("lspsaga").setup({
            lightbulb = {
                virtual_text = false,
            },
            diagnostic = {
                on_insert = false,
            },
        })

        vim.keymap.set("n", "<leader>ca", "<CMD>Lspsaga code_action<CR>", { noremap = true, silent = true })
    end,
    dependencies = {
        "nvim-treesitter/nvim-treesitter", -- optional
        "nvim-tree/nvim-web-devicons", -- optional
    },
}
