local cmp = require('cmp')

local cmp_mappings = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-y>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({
        select = false
    }),
    ["<C-j>"] = cmp.mapping(function(fallback)
        cmp.mapping.abort()
        local copilot_keys = vim.fn["copilot#Accept"]()
        if copilot_keys ~= "" then
            vim.api.nvim_feedkeys(copilot_keys, "i", true)
        else
            fallback()
        end
    end, {"i", "s"}),
});

cmp.setup({
    sources = {{
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
