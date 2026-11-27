-- AI CLIs offered by Sidekick (␣ac toggle, ␣aj pick, ␣as send selection / this).
local tools = {
  claude = {},
  codex = {},
  copilot = {},
  pi = {},
  agy = {
    cmd = { "agy" },
    -- agy drops input that arrives while it is still drawing its startup screen
    ready_delay = 1500,
    is_proc = "\\<agy\\>",
    continue = { "--continue" },
  },
  devin = {
    cmd = { "devin" },
    is_proc = "\\<devin\\>",
    resume = { "--resume" },
    continue = { "--continue" },
  },
}

return {
  {
    "folke/sidekick.nvim",
    opts = { cli = { tools = tools } },
    keys = {
      {
        "<leader>ab",
        function()
          local open = vim.iter(vim.api.nvim_tabpage_list_wins(0)):any(function(win)
            return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "sidekick_terminal"
          end)
          if open then
            require("sidekick.cli").hide({ all = true })
          else
            require("sidekick.cli").show({ focus = true })
          end
        end,
        desc = "Toggle Agent Panel",
      },
    },
    config = function(_, opts)
      require("sidekick").setup(opts)

      -- Optional per-tool `ready_delay` (ms) on top of Sidekick's own readiness check.
      local Terminal = require("sidekick.cli.terminal")
      local on_ready = Terminal.on_ready
      Terminal.on_ready = function(self)
        local tool = self.tool and tools[self.tool.name]
        local delay = tool and tool.ready_delay
        if not delay then
          return on_ready(self)
        end
        vim.defer_fn(function()
          on_ready(self)
        end, delay)
      end
      -- Sidekick merges its built-in tool list into ours; keep only the CLIs above.
      local configured = require("sidekick.config").cli.tools
      for name in pairs(configured) do
        if not tools[name] then
          configured[name] = nil
        end
      end
    end,
  },
}
