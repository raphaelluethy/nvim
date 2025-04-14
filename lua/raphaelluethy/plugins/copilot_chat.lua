return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'zbirenbaum/copilot.lua' }, -- or zbirenbaum/copilot.lua
      -- { 'github/copilot.vim' },
      { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    config = function()
      require('copilot').setup {
        copilot_model = 'gpt-4o-copilot',
        suggestion = {
          enabled = true,
          auto_trigger = true,
          hide_during_completion = false,
          keymap = {
            accept = '<Tab>',
            accept_word = false,
            accept_line = false,
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<C-]>',
          },
        },
      }
      require('CopilotChat').setup {
        -- See Configuration section for options
      }

      -- Define the functions globally
      _G.quick_chat_with_copilot = function()
        local input = vim.fn.input 'Quick Chat: '
        if input ~= '' then
          require('CopilotChat').ask(input, { selection = require('CopilotChat.select').buffer })
        end
      end

      _G.show_prompt_actions_with_telescope = function()
        local actions = require 'CopilotChat.actions'
        require('CopilotChat.integrations.telescope').pick(actions.prompt_actions())
      end

      _G.perplexity_search = function()
        local input = vim.fn.input 'Perplexity: '
        if input ~= '' then
          require('CopilotChat').ask(input, {
            agent = 'perplexityai',
            selection = false,
          })
        end
      end

      -- Set the keymaps
      vim.keymap.set('n', '<leader>ct', ':CopilotChatToggle<CR>', { desc = 'Copilot Chat' })
      vim.keymap.set('n', '<leader>ccq', ':lua quick_chat_with_copilot()<CR>', { noremap = true, silent = true, desc = 'CopilotChat - Quick chat' })
      vim.keymap.set(
        'n',
        '<leader>ccp',
        ':lua show_prompt_actions_with_telescope()<CR>',
        { noremap = true, silent = true, desc = 'CopilotChat - Prompt actions' }
      )
      vim.keymap.set('n', '<leader>ccs', ':lua perplexity_search()<CR>', { noremap = true, silent = true, desc = 'CopilotChat - Perplexity Search' })
    end,
  },
}
