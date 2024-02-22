return {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
        require("ibl").setup({
            debounce = 100,
            whitespace = { highlight = { "Whitespace" } },
        })
    end,
}
