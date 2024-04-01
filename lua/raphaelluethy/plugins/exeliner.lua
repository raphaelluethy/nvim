return {
    "jinh0/eyeliner.nvim",
    config = function()
        require("eyeliner").setup {
            highlight_on_key = true, -- show highlights only after keypress
            dim = true               -- dim all other characters if set to true (recommended!)
        }

        vim.api.nvim_set_hl(0, "EyelinerPrimary", { fg = "#f92672", bold = true, underline = true })
        vim.api.nvim_set_hl(0, "EyelinerSecondary", { fg = "#ffffff", underline = true })
    end
}
