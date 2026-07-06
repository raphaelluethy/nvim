return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {},
  cmd = "Trouble",
  keys = {
    { "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>", desc = "Toggle Trouble diagnostics" },
  },
}
