return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    main = 'nvim-treesitter',
    opts = {},
    config = function()
      require('nvim-treesitter').setup({})

      -- Enable treesitter highlighting for future buffers
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })

      -- Enable for current buffer if it has a filetype
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].filetype ~= '' then
        pcall(vim.treesitter.start, buf)
      end
    end,
  }
}
