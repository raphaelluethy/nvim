local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system(
        {"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", -- latest stable release
         lazypath})
end
vim.opt.rtp:prepend(lazypath)

local plugins = {{
    'nvim-telescope/telescope.nvim',
    tag = '0.1.3',
    -- or                              , branch = '0.1.1',
    dependencies = {'nvim-lua/plenary.nvim'}
}, -- themeing
'loctvl842/monokai-pro.nvim', 'nvim-tree/nvim-web-devicons', -- blazingly fast
'theprimeagen/harpoon', -- lualine
'nvim-lualine/lualine.nvim', -- treesitter
'nvim-treesitter/nvim-treesitter', {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = {"nvim-treesitter"}
}, -- support editorconfig
'editorconfig/editorconfig-vim', -- comments
'numToStr/Comment.nvim', -- lsp zero
{
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    requires = {{"nvim-lua/plenary.nvim"}}
}, {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v2.x',
    dependencies = { -- LSP Support
    {'neovim/nvim-lspconfig'}, -- Required
    { -- Optional
        'williamboman/mason.nvim',
        build = function()
            pcall(vim.cmd, 'MasonUpdate')
        end
    }, {'williamboman/mason-lspconfig.nvim'}, -- Optional
    -- Autocompletion
    {'hrsh7th/nvim-cmp'}, -- Required
    {'hrsh7th/cmp-nvim-lsp'}, -- Required
    {'saadparwaiz1/cmp_luasnip'}, {'L3MON4D3/LuaSnip'} -- Requireddd
    }
}, -- autopairs
'windwp/nvim-autopairs', -- rainbow-parens
'hiphish/nvim-ts-rainbow2', -- colorizer
'norcalli/nvim-colorizer.lua', -- undotree
'mbbill/undotree', -- gitsigns
'lewis6991/gitsigns.nvim', -- copilot 
'zbirenbaum/copilot.lua', 'zbirenbaum/copilot-cmp', -- rust
'simrat39/rust-tools.nvim', 'nvim-lua/plenary.nvim', 'mfussenegger/nvim-dap', "pmizio/typescript-tools.nvim"}

local opts = {}

require("lazy").setup(plugins, opts)
