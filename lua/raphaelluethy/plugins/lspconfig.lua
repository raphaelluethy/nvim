return {
    "neovim/nvim-lspconfig",
    opts = {
        inlay_hints = {
            enabled = true
        }
    },
    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim", "j-hui/fidget.nvim" },
    config = function()
        require("fidget").setup()
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = { "lua_ls", "rust_analyzer", "tsserver", "gopls", "sqls" },
            handlers = { function(server_name) -- default handler
                require("lspconfig")[server_name].setup {
                    on_attach = function(client, bufnr)
                        if client.server_capabilities.inlayHintProvider then
                            vim.lsp.inlay_hint.enable(bufnr, true)
                        end
                    end
                }
            end, require("lspconfig").lua_ls.setup({
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" }
                        },
                        telemetry = {
                            enable = false
                        },
                        hint = {
                            enable = true
                        }
                    }
                }
            }), require("lspconfig").gopls.setup({
                settings = {
                    gopls = {
                        analyses = {
                            unusedparams = true
                        },
                        ["ui.inlayhint.hints"] = {
                            compositeLiteralFields = true,
                            constantValues = true,
                            parameterNames = true
                        },
                        staticcheck = true
                    }
                }
            }),
                require("lspconfig").tsserver.setup({
                    settings = {
                        tsserver = {
                            on = {
                                importAll = true
                            }
                        }
                    }
                }),
            }
        })
        -- vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        --     border = "rounded"
        -- })
        -- vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        --     border = "rounded"
        -- })
        require("lspconfig.ui.windows").default_options.border = "rounded"

        --
        -- vim.keymap.set("n", "gd", function()
        --     vim.lsp.buf.definition()
        -- end, opts)
        -- vim.keymap.set("n", "K", function()
        --     vim.lsp.buf.hover()
        -- end, opts)
        -- vim.keymap.set("n", "<leader>ca", function()
        --     vim.lsp.buf.code_action()
        -- end, opts)
        -- vim.keymap.set("n", "<leader>vrr", function()
        --     vim.lsp.buf.references()
        -- end, opts)
        -- vim.keymap.set("i", "<C-h>", function()
        --     vim.lsp.buf.signature_help()
        -- end, opts)

        -- enable inline diagnostics
        vim.diagnostic.config({
            virtual_text = true,
            update_in_insert = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = ""
            }
        })
        local wk = require("which-key")
        wk.register({
            ["<leader>lf"] = { ':lua vim.lsp.buf.format({async = true})<CR> <BAR> <cmd>update<CR>', "Format File with LSP"}
        })
    end
}
