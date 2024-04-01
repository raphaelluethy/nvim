return {
    "loctvl842/monokai-pro.nvim",
    priority = 1000,
    config = function()
        require("monokai-pro").setup({
            transparent_background = false,
            terminal_colors = true,
            devicons = true, -- highlight the icons of `nvim-web-devicons`
            styles = {
                comment = { italic = true },
                keyword = { italic = false },      -- any other keyword
                type = { italic = true },          -- (preferred) int, long, char, etc
                storageclass = { italic = true },  -- static, register, volatile, etc
                structure = { italic = true },     -- struct, union, enum, etc
                parameter = { italic = true },     -- parameter pass in function
                annotation = { italic = true },
                tag_attribute = { italic = true }, -- attribute of tag in reactjs
            },
            filter = "spectrum",                   -- classic | octagon | pro | machine | ristretto | spectrum
            -- Enable this will disable filter option
            inc_search = "background",             -- underline | background
            background_clear = {
                "float_win",
                "toggleterm",
                "telescope",
                --     -- "which-key",
                --     "renamer",
                --     "notify",
                --     -- "nvim-tree",
                "neo-tree",
                --     -- "bufferline", -- better used if background of `neo-tree` or `nvim-tree` is cleared
                -- }, -- "float_win", "toggleterm", "telescope", "which-key", "renamer", "neo-tree", "nvim-tree", "bufferline"
                -- plugins = {
                --     bufferline = {
                --         underline_selected = false,
                --         underline_visible = false,
                --     },
                indent_blankline = {
                    context_highlight = "pro", -- default | pro
                    context_start_underline = true,
                },
            },
            override = function()
                return {
                    WinSeparator = { fg = "#ffffff" }
                }
            end

        })
        vim.cmd.colorscheme 'monokai-pro'
        vim.cmd.hi 'Comment gui=none'
        local set_hl_for_floating_window = function()
            vim.api.nvim_set_hl(0, 'NormalFloat', {
                link = 'Normal',
            })
            vim.api.nvim_set_hl(0, 'FloatBorder', {
                bg = 'none',
            })
        end

        set_hl_for_floating_window()

        vim.api.nvim_create_autocmd('ColorScheme', {
            pattern = '*',
            desc = 'Avoid overwritten by loading color schemes later',
            callback = set_hl_for_floating_window,
        })
    end,
}
