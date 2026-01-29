return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {},
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump to character" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash select treesitter node" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Flash remote (operator pending)" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash treesitter search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash search in cmdline" },
  },
}
