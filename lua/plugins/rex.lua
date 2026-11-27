local function rex_term_nav(dir)
  return function(self)
    return self:is_floating() and "<c-" .. dir .. ">" or vim.schedule(function()
      require("config.rex").navigate(dir)
    end)
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          keys = {
            nav_h = { "<C-h>", rex_term_nav("h"), desc = "Go to Left Window / Rex Pane", expr = true, mode = "t" },
            nav_j = { "<C-j>", rex_term_nav("j"), desc = "Go to Lower Window / Rex Pane", expr = true, mode = "t" },
            nav_k = { "<C-k>", rex_term_nav("k"), desc = "Go to Upper Window / Rex Pane", expr = true, mode = "t" },
            nav_l = { "<C-l>", rex_term_nav("l"), desc = "Go to Right Window / Rex Pane", expr = true, mode = "t" },
          },
        },
      },
    },
  },
}
