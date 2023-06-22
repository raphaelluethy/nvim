require('monokai-pro').setup {
    -- ... your config
    transparent_background = true,
    terminal_colors = true,
    devicons = true, -- highlight the icons of `nvim-web-devicons`
    styles = {
        comment = {
            italic = true
        },
        keyword = {
            italic = true
        }, -- any other keyword
        type = {
            italic = true
        }, -- (preferred) int, long, char, etc
        storageclass = {
            italic = true
        }, -- static, register, volatile, etc
        structure = {
            italic = true
        }, -- struct, union, enum, etc
        parameter = {
            italic = true
        }, -- parameter pass in function
        annotation = {
            italic = true
        },
        tag_attribute = {
            italic = true
        } -- attribute of tag in reactjs
    },
    filter = 'pro', -- classic | octagon | pro | machine | ristretto | spectrum
    inc_search = 'background', -- underline | background
    background_clear = { -- "float_win",
    'toggleterm', 'telescope', 'which-key', 'renamer', 'notify', -- "nvim-tree",
    'neo-tree' -- "bufferline", -- better used if background of `neo-tree` or `nvim-tree` is cleared
}, -- "float_win", "toggleterm", "telescope", "which-key", "renamer", "neo-tree", "nvim-tree", "bufferline"
plugins = {
    indent_blankline = {
        context_highlight = 'default', -- default | pro
        context_start_underline = false
    }
},
override = function(c)
end
}
vim.cmd [[colorscheme monokai-pro]]