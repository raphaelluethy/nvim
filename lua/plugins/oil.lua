return {
  "stevearc/oil.nvim",
  version = "*",
  lazy = false,
  dependencies = { "nvim-mini/mini.icons" },
  ---@module "oil"
  ---@type oil.SetupOpts
  opts = {
    default_file_explorer = true,
    view_options = { show_hidden = true },
  },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory (Oil)" },
  },
}
