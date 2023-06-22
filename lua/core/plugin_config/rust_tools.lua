local rt = require('rust-tools')
rt.setup({
    server = {
      on_attach = function(_, bufnr)
        -- Hover actions
        vim.keymap.set("n", "<C-a>", rt.hover_actions.hover_actions, { buffer = bufnr })
      end,
    },
  })
rt.inlay_hints.enable()
