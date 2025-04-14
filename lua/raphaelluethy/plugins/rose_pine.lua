return {
  -- lua/plugins/rose-pine.lua
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    config = function()
      require('rose-pine').setup {
        disable_background = true,
        italic = false,
      }
      -- vim.cmd [[colorscheme rose-pine]]
    end,
  },
}
