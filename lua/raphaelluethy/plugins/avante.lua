return {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  lazy = false,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    provider = 'claude',
    hints = {
      enabled = true,
    },
  },
  build = 'make',
  dependencies = {
    {
      'stevearc/dressing.nvim',
      opts = {
        input = {
          enabled = false,
        },
      },
    },
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    --- The below dependencies are optional,
    'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
    {
      -- support for image pasting
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      config = function()
        require('render-markdown').setup {
          file_types = { 'markdown', 'Avante' },
          code = {
            enabled = true,
            sign = true,
            style = 'language',
            position = 'left',
            language_pad = 0,
            disable_background = { 'diff' },
            width = 'full',
            left_pad = 0,
            right_pad = 0,
            min_width = 0,
            border = 'thin',
            -- Highlight for code blocks
            highlight = 'NormalFloat',
            -- Highlight for inline code
            highlight_inline = 'NormalFloat',
          },
          heading = { sign = false, icons = {} },
          dash = { enabled = false },
          link = { enabled = false },
          bullet = { enabled = false },
          quote = { enabled = true },
        }
      end,
    },
  },
}
