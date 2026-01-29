return {
  "smjonas/inc-rename.nvim",
  opts = {},
  config = function()
    require("inc_rename").setup({})
    vim.keymap.set("n", "<leader>rn", ":IncRename ", { desc = "Incremental rename" })
  end,
}
