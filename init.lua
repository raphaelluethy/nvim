require("raphaelluethy")

local augroup = vim.api.nvim_create_augroup
local RaphaelluethyGroup = augroup('raphaelluethy', {})

local autocmd = vim.api.nvim_create_autocmd

autocmd('LspAttach', {
    group = RaphaelluethyGroup,
    callback = function(e)
        local opts = {
            buffer = e.buf
        }

        vim.keymap.set("n", "gd", function()
            vim.lsp.buf.definition()
        end, opts)
        vim.keymap.set("n", "gi", function()
            vim.lsp.buf.implementation()
        end, opts)
        vim.keymap.set("n", "gr", function()
            vim.lsp.buf.references()
        end, opts)
        vim.keymap.set("n", "K", function()
            vim.lsp.buf.hover()
        end, opts)
        vim.keymap.set("n", "<leader>vws", function()
            vim.lsp.buf.workspace_symbol()
        end, opts)
        vim.keymap.set("n", "<leader>vd", function()
            vim.diagnostic.open_float()
        end, opts)
        vim.keymap.set("n", "[d", function()
            vim.diagnostic.goto_next()
        end, opts)
        vim.keymap.set("n", "]d", function()
            vim.diagnostic.goto_prev()
        end, opts)
        vim.keymap.set("n", "<leader>vca", function()
            vim.lsp.buf.code_action()
        end, opts)
        vim.keymap.set("n", "<leader>vrr", function()
            vim.lsp.buf.references()
        end, opts)
        vim.keymap.set("n", "<leader>vrn", function()
            vim.lsp.buf.rename()
        end, opts)
        vim.keymap.set("i", "<C-h>", function()
            vim.lsp.buf.signature_help()
        end, opts)

        -- vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
        -- vim.keymap.set("n", "gi", vim.lsp.buf.implementation, keymap_opts)
        -- vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, keymap_opts)
        -- vim.keymap.set("n", "gd", vim.lsp.buf.definition, keymap_opts)
       
    end
})
