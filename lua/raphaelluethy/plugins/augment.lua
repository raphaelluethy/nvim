return {
  {
    'augmentcode/augment.vim',
    init = function()
      -- These options must be set before the plugin is loaded
      vim.g.augment_workspace_folders = {
        '/Users/raphael.luethy@fhnw.ch/Documents/projects/private/adapp',
        '/Users/raphael.luethy@fhnw.ch/Documents/projects/fhnw/devmanto',
        '/Users/raphael.luethy@fhnw.ch/Documents/projects/private/adaptinator/',
        '/Users/raphael.luethy@fhnw.ch/Documents/projects/private/BabySleep-Backend/',
      }

      vim.g.augment_disable_tab_mapping = true
      vim.g.augment_disable_completions = true

      -- run cmd augment chat
      vim.keymap.set('n', '<leader>aa', ':Augment chat<CR>')
      vim.keymap.set('v', '<leader>aa', ':Augment chat<CR>')
    end,
  },
}
