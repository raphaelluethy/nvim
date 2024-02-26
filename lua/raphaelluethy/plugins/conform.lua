return {
    "stevearc/conform.nvim",
    config = function()
        require("conform").setup({
            notify_on_error = false,
            -- auto formatting
            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true
            },
            formatters_by_ft = {
                lua = {"stylua"},
                -- Conform will run multiple formatters sequentially
                python = {"isort", "black"},
                -- Use a sub-list to run only the first available formatter
                javascript = {{"biomejs", "prettier"}},
                javascriptreact = {{"biomejs", "prettier"}},
                typescript = {{"biomejs", "prettier"}},
                typescriptreact = {{"biomejs", "prettier"}},
                go = {"goimports", "gofmt"}
            }
        })
        vim.keymap.set({"n", "v"}, "<leader>f", function()
            require("conform").format({
                lsp_fallback = true,
                timeout_ms = 500
            })
        end, {
            desc = "Format file or range using Conform"
        })
    end
}
