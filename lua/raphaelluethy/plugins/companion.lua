return {
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('codecompanion').setup {
        adapters = {
          anthropic = function()
            return require('codecompanion.adapters').extend('anthropic', {
              schema = {
                model = {
                  default = 'claude-3-5-sonnet-latest',
                },
              },
            })
          end,
          groq = function()
            return require('codecompanion.adapters').extend('openai', {
              env = {
                api_key = 'GROQ_API_KEY',
              },
              name = 'Groq',
              url = 'https://api.groq.com/openai/v1/chat/completions',
              schema = {
                model = {
                  default = 'deepseek-r1-distill-llama-70b',
                },
              },
              max_tokens = {
                default = 4096,
              },
              temperature = {
                default = 1,
              },
              handlers = {
                form_messages = function(_, messages)
                  for _, msg in ipairs(messages) do
                    -- Remove 'id' and 'opts' properties from all messages
                    msg.id = nil
                    msg.opts = nil
                    -- Ensure 'name' is a string if present, otherwise remove it
                    if msg.name then
                      msg.name = tostring(msg.name)
                    else
                      msg.name = nil
                    end
                    -- Ensure only supported properties are present
                    local supported_props = { role = true, content = true, name = true }
                    for prop in pairs(msg) do
                      if not supported_props[prop] then
                        msg[prop] = nil
                      end
                    end
                  end
                  return { messages = messages }
                end,
              },
            })
          end,
          deepseek_reasoner = function()
            return require('codecompanion.adapters').extend('deepseek', {
              env = {
                api_key = 'DEEPSEEK_API_KEY',
              },
              schema = {
                model = {
                  default = 'deepseek-reasoner',
                  -- default = 'deepseek-chat',
                },
              },
            })
          end,
          deepseek = function()
            return require('codecompanion.adapters').extend('deepseek', {
              env = {
                api_key = 'DEEPSEEK_API_KEY',
              },
              schema = {
                model = {
                  default = 'deepseek-chat',
                },
              },
            })
          end,
        },
        display = {
          diff = {
            provider = 'mini_diff',
          },
          chat = {
            show_settings = false,
          },
        },
        opts = {
          log_level = 'DEBUG',
        },
        strategies = {
          chat = {
            adapter = 'groq',
          },
          inline = {
            adapter = 'anthropic',
          },
        },
      }

      vim.api.nvim_set_keymap('n', '<leader>al', '<cmd>CodeCompanionActions<cr>', { noremap = true, silent = true, desc = 'Open CodeCompanion Actions' })
      vim.api.nvim_set_keymap('n', '<leader>aa', '<cmd>CodeCompanionChat Toggle<cr>', { noremap = true, silent = true, desc = 'Toggle CodeCompanion Chat' })
      vim.api.nvim_set_keymap('n', '<leader>ae', '<cmd>CodeCompanion<cr>', {
        noremap = true,
        silent = true,
        desc = 'Edit CodeCompanion Chat',
      })
      vim.api.nvim_set_keymap('v', '<leader>aa', '<cmd>CodeCompanionChat Toggle<cr>', { noremap = true, silent = true, desc = 'Toggle CodeCompanion Chat' })
      vim.api.nvim_set_keymap('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { noremap = true, silent = true, desc = 'Add selected to CodeCompanion Chat' })
      vim.api.nvim_set_keymap('v', '<leader>ae', '<cmd>CodeCompanion<cr>', {
        noremap = true,
        silent = true,
        desc = 'Edit CodeCompanion Chat',
      })

      vim.cmd [[cab cc CodeCompanion]]
    end,
  },
}
