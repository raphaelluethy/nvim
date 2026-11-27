return {
  {
    "rcarriga/nvim-dap-ui",
    enabled = false,
  },
  {
    "igorlfs/nvim-dap-view",
    version = "1.*",
    ---@module "dap-view"
    ---@type dapview.Config
    opts = {
      auto_toggle = true,
    },
    keys = {
      { "<leader>du", "<cmd>DapViewToggle<cr>", desc = "Dap View" },
      { "<leader>de", "<cmd>DapViewHover<cr>", mode = { "n", "x" }, desc = "Dap Hover" },
      { "<leader>dW", "<cmd>DapViewWatch<cr>", mode = { "n", "x" }, desc = "Dap Watch" },
    },
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "igorlfs/nvim-dap-view",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: Continue/Start" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
    },
  },
}
