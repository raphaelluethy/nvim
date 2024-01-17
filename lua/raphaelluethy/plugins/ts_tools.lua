return {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    config = function()
        require("typescript-tools").setup {
            settings = {
                typescript = {
                    inlayHints = {
                        -- taken from https://github.com/typescript-language-server/typescript-language-server#workspacedidchangeconfiguration
                        includeInlayEnumMemberValueHints = true,
                        includeInlayFunctionLikeReturnTypeHints = true,
                        includeInlayFunctionParameterTypeHints = true,
                        includeInlayParameterNameHints = 'all',
                        includeInlayParameterNameHintsWhenArgumentMatchesName = true, -- false
                        includeInlayPropertyDeclarationTypeHints = true,
                        includeInlayVariableTypeHints = true,
                        includeInlayVariableTypeHintsWhenTypeMatchesName = true -- false
                    }
                },
                javascript = {
                    inlayHints = {
                        includeInlayEnumMemberValueHints = true,
                        includeInlayFunctionLikeReturnTypeHints = true,
                        includeInlayFunctionParameterTypeHints = true,
                        includeInlayParameterNameHints = 'all',
                        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                        includeInlayPropertyDeclarationTypeHints = true,
                        includeInlayVariableTypeHints = true,
                        includeInlayVariableTypeHintsWhenTypeMatchesName = true
                    }
                },
                tsserver_file_preferences = {
                    includeInlayParameterNameHints = "none", -- "literals", "all" are currently buggy
                    includeCompletionsForModuleExports = true,
                    quotePreference = "auto"
                },
                tsserver_format_options = {
                    allowIncompleteCompletions = false,
                    allowRenameOfImportPath = false,
                }
            }
        }
    end
}
