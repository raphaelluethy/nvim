return {
    "loctvl842/monokai-pro.nvim",
    config = function()
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
                    italic = false
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
            filter = 'spectrum', -- classic | octagon | pro | machine | ristretto | spectrum
            inc_search = 'background', -- underline | background
            background_clear = { -- "float_win",
            'toggleterm', 'telescope', 'which-key', 'renamer', 'notify', -- "nvim-tree",
            'neo-tree', 'float_win' -- "bufferline", -- better used if background of `neo-tree` or `nvim-tree` is cleared
            },
            plugins = {
                indent_blankline = {
                    context_highlight = 'default', -- default | pro
                    context_start_underline = false
                }
            }
        }
        vim.cmd [[colorscheme monokai-pro]]

    end
}
