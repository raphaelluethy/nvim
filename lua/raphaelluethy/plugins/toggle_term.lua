return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    config = function()
      require('toggleterm').setup()
      vim.keymap.set('n', '<leader>tf', '<CMD>ToggleTerm direction=float<cr>', { desc = '[T]toggleterm [F]loat' })
      vim.keymap.set('n', '<leader>tv', '<CMD>ToggleTerm direction=vertical<cr>', { desc = '[T]toggleterm [V]ertical' })
    end,
  },
}
