return {
    "stevearc/conform.nvim",
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                -- Conform will run multiple formatters sequentially
                python = { "isort", "black" },
                -- Use a sub-list to run only the first available formatter
                javascript = { { "prettier" } },
                javascriptreact = { { "prettier" } },
                typescript = { { "prettier" } },
                typescriptreact = { { "prettier" } },
                go = { "goimports", "gofmt" },
            },
        })
        vim.keymap.set({ "n", "v" }, "<leader>f", function()
            require("conform").format({
                lsp_fallback = true,
                async = false,
                timeout_ms = 500,
            })
        end, { desc = "Format file or range using Conform" })
    end,
}
