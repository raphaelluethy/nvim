return {
  {
    'augmentcode/augment.vim',
    init = function()
      -- These options must be set before the plugin is loaded
      vim.g.augment_disable_tab_mapping = true
      vim.g.augment_disable_completions = true
    end,
  },
}
