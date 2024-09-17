return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    -- disable netrw at the very start of your init.lua
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- optionally enable 24-bit colour
    vim.opt.termguicolors = true

    -- OR setup with some options
    require('nvim-tree').setup {
      actions = {
        open_file = {
          quit_on_open = true,
        },
      },
      sort = {
        sorter = 'case_sensitive',
      },
      view = {
        width = 40,
        side = 'right',
      },
      renderer = {
        group_empty = true,
      },
    }

    vim.keymap.set('n', '<C-b>', ':NvimTreeToggle<CR>', { desc = '[N]vim [E]xplorer', silent = true })
  end,
}
