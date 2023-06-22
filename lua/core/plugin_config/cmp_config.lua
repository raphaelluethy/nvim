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
    ["<C-Space>"] = cmp.mapping.complete(),
});

cmp.setup({
    sources = {{
        name = "copilot",
        group_index = 2
    }, {
        name = 'nvim_lsp',
        group_index = 2
    }, {
        name = 'path',
        group_index = 2
    }, {
        name = 'luasnip',
        group_index = 2
    }, {
        name = 'buffer',
        keyword_length = 5
    }},
    mapping = cmp_mappings
})
