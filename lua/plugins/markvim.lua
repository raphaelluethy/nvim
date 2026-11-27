local function markdown_buffer()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "markdown" and vim.bo[buf].buftype == "" and not vim.b[buf].markvim_mode then
    return buf
  end
end

return {
  dir = "~/Documents/projects/private/markvim",
  name = "markvim",
  ft = "markdown",
  cmd = "Markvim",
  keys = {
    {
      "<leader>um",
      function()
        local buf = markdown_buffer()
        if buf then
          require("markvim").toggle(buf)
        end
      end,
      desc = "Toggle Markdown rendering (Markvim)",
    },
    {
      "<leader>uM",
      function()
        local buf = markdown_buffer()
        if buf then
          local next_mode = { live = "preview", preview = "split", split = "live" }
          local mode = next_mode[require("markvim").mode(buf) or "live"]
          require("markvim").set_mode(mode, buf)
          vim.notify("markvim: " .. mode, vim.log.levels.INFO)
        end
      end,
      desc = "Cycle Markdown mode (live/preview/split)",
    },
  },
  opts = {
    mode = "live",
    float_mode = "preview",
  },
}
