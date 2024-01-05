return {
    "nvim-lualine/lualine.nvim",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        require('lualine').setup {
            options = {
                icons_enabled = true,
                theme = 'onedark'
            },
            sections = {
                lualine_a = {{
                    'filename',
                    path = 1
                }},
                lualine_b = {{
                    'branch',
                    icon = ''
                }},
                lualine_c = {{
                    'diff',
                    colored = true,
                    color_added = '#a6e22e',
                    color_modified = '#e6db74',
                    color_removed = '#f92672',
                    symbols = {added = '+', modified = '~', removed = '-'}
                }},
            }
        }
    end
}
