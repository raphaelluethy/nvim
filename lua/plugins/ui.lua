return {
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      -- rust-analyzer opens a progress token per task (cargo check, indexing, proc-macros, …);
      -- noice gives each its own line in the mini view, so cap its height.
      views = {
        mini = {
          size = { max_height = 3 },
        },
      },
    },
  },
}
