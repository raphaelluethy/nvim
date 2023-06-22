require('nvim-treesitter.configs').setup {
    -- A list of parser names, or "all"
    ensure_installed = {"c", "lua", "rust", "vim"},

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true
    },
    rainbow = {
        enable = true,
        -- list of languages you want to disable the plugin for
        -- disable = { 'jsx', 'cpp' },
        -- Which query to use for finding delimiters
        query = 'rainbow-parens',
        -- Highlight the entire buffer all at once
        strategy = require('ts-rainbow').strategy.global
    }
}
