return {
  "JetBrains/intellij-lsp.nvim",
  lazy = false,
  dependencies = { "mfussenegger/nvim-dap" },
  opts = {
    region = "europe",
    data_sharing = "none",
    progress = false,
    single_key_select = false,
    autotrigger = false,
    word_triggers = false,
    enter_accepts_completion = false,
    completeopt = false,
    signature_help = false,
    document_highlight = false,
    keymaps = false,
    colorscheme = false,
  },
  config = function(_, opts)
    local debug = require("intellij-lsp.debug")
    debug.set_keymaps = function(bufnr)
      local function map(lhs, rhs, desc, mode)
        vim.keymap.set(mode or "n", lhs, rhs, { buffer = bufnr, desc = desc })
      end
      local function debug_class()
        require("intellij-lsp.run").run_at_cursor(false)
      end
      local function continue()
        if require("dap").session() then
          require("dap").continue()
        else
          debug_class()
        end
      end

      map("<F5>", continue, "Debug: Continue/Start (IntelliJ)")
      map("<leader>dc", continue, "Debug: Continue/Start (IntelliJ)")
      map("<leader>dd", debug_class, "Debug: Class at cursor (IntelliJ)")
      map("<leader>de", debug.evaluate_at_cursor, "Debug: Evaluate (IntelliJ)", { "n", "x" })
      map("<leader>dw", debug.watch_at_cursor, "Debug: Watch (IntelliJ)", { "n", "x" })
      map("<leader>dv", debug.open, "Debug: IntelliJ panel")
    end

    require("intellij-lsp").setup(opts)
  end,
}
