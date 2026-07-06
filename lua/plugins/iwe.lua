return {
  "iwe-org/iwe.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("iwe").setup()
  end,
}
