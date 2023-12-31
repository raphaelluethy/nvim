return {
    "hrsh7th/nvim-cmp",
    dependencies = {"hrsh7th/nvim-cmp", "hrsh7th/cmp-nvim-lsp", "saadparwaiz1/cmp_luasnip", "L3MON4D3/LuaSnip"},
    config = function()
        local cmp = require('cmp')

        local has_words_before = function()
            if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
                return false
            end
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
        end

        local cmp_mappings = cmp.mapping.preset.insert({
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-y>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm({
                select = false
            }),
            ["<Tab>"] = vim.schedule_wrap(function(fallback)
                if cmp.visible() and has_words_before() then
                    cmp.select_next_item({
                        behavior = cmp.SelectBehavior.Select
                    })
                else
                    fallback()
                end
            end),
            ["<C-Space>"] = cmp.mapping.complete()
        });

        cmp.setup({
            experimental = {
                ghost_text = true
            },
            sources = {{
                name = "copilot"
            }, {
                name = 'nvim_lsp'
            }, {
                name = 'path'
            }, {
                name = 'luasnip'
            }, {
                name = 'buffer',
                keyword_length = 5
            }},
            mapping = cmp_mappings
        })

        -- TODO: Figure out how to get this integrated
        -- cmp.setup({
        --     snippet = {
        --         -- REQUIRED - you must specify a snippet engine
        --         expand = function(args)
        --             -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        --             require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        --             -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        --             -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        --         end
        --     },
        --     window = {
        --         -- completion = cmp.config.window.bordered(),
        --         -- documentation = cmp.config.window.bordered(),
        --     },
        --     mapping = cmp.mapping.preset.insert({
        --         ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        --         ['<C-f>'] = cmp.mapping.scroll_docs(4),
        --         ['<C-Space>'] = cmp.mapping.complete(),
        --         ['<C-e>'] = cmp.mapping.abort(),
        --         ['<CR>'] = cmp.mapping.confirm({
        --             select = true
        --         }) -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        --     }),
        --     sources = cmp.config.sources({{
        --         name = 'nvim_lsp'
        --     }, {
        --         name = 'luasnip'
        --     } -- For luasnip users.
        --     -- { name = 'ultisnips' }, -- For ultisnips users.
        --     -- { name = 'snippy' }, -- For snippy users.
        --     }, {{
        --         name = 'buffer'
        --     }})
        -- })

        -- -- Set configuration for specific filetype.
        -- cmp.setup.filetype('gitcommit', {
        --     sources = cmp.config.sources({{
        --         name = 'git'
        --     } -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
        --     }, {{
        --         name = 'buffer'
        --     }})
        -- })

        -- -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
        -- cmp.setup.cmdline({'/', '?'}, {
        --     mapping = cmp.mapping.preset.cmdline(),
        --     sources = {{
        --         name = 'buffer'
        --     }}
        -- })

        -- -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
        -- cmp.setup.cmdline(':', {
        --     mapping = cmp.mapping.preset.cmdline(),
        --     sources = cmp.config.sources({{
        --         name = 'path'
        --     }}, {{
        --         name = 'cmdline'
        --     }})
        -- })

        -- -- Set up lspconfig.
        -- local capabilities = require('cmp_nvim_lsp').default_capabilities()
        -- -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
        -- require('lspconfig')['rust_analyzer'].setup {
        --     capabilities = capabilities
        -- }
        -- require('lspconfig')['tsserver'].setup {
        --     capabilities = capabilities
        -- }
        -- require('lspconfig')['gopls'].setup {
        --     capabilities = capabilities
        -- }
    end
}
