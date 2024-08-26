return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'leoluz/nvim-dap-go',
      'mfussenegger/nvim-dap-python',
      'rcarriga/nvim-dap-ui',
      'theHamsta/nvim-dap-virtual-text',
      'nvim-neotest/nvim-nio',
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',
      'mxsdev/nvim-dap-vscode-js',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      require('mason-nvim-dap').setup {
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_setup = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {},

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure that you have the debuggers for the langs you want
          'delve',
          'python',
          'javadbg',
          'javatest',
          'kotlin',
          'js',
        },
      }
      require('dap-vscode-js').setup {
        debugger_path = '~/.local/share/lvim/mason/packages/js-debug-adapter',
        debugger_cmd = { 'js-debug-adapter' },
        adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
        node_path = 'node',
      }

      -- if I get the sourcemap error again, just do this: https://github.com/mxsdev/nvim-dap-vscode-js/issues/35#issuecomment-1458311404

      for _, language in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
        dap.configurations[language] = {
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Debug TypeScript',
            program = '${workspaceFolder}/path/to/your/ts-file.ts',
            runtimeExecutable = 'node',
            runtimeArgs = { '-r', 'ts-node/register' },
            outFiles = { '${workspaceFolder}/path/to/your/ts-file.js' },
            sourceMaps = true,
            stopOnEntry = false,
            args = {},
            cwd = '${workspaceFolder}',
            protocol = 'inspector',
            console = 'integratedTerminal',
            internalConsoleOptions = 'openOnSessionStart',
          },
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            skipFiles = { '<node_internals>/**', 'node_modules/**' },
          },
          {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}',
          },
        }
      end

      -- Dap UI setup
      -- For more information, see |:help nvim-dap-ui|
      dapui.setup()

      require('dap-go').setup()

      require('nvim-dap-virtual-text').setup {}

      -- -- Handled by nvim-dap-go
      -- dap.adapters.go = {
      --     type = "server",
      --     port = "${port}",
      --     executable = {
      --         command = "dlv",
      --         args = { "dap", "-l", "127.0.0.1:${port}" },
      --     },
      -- }

      vim.keymap.set('n', '<space>db', dap.toggle_breakpoint)
      vim.keymap.set('n', '<space>drc', dap.run_to_cursor)

      -- Eval var under cursor
      vim.keymap.set('n', '<space>?', function()
        require('dapui').eval(nil, { enter = true })
      end)

      vim.keymap.set('n', '<F1>', dap.continue)
      vim.keymap.set('n', '<F2>', dap.step_into)
      vim.keymap.set('n', '<F3>', dap.step_over)
      vim.keymap.set('n', '<F4>', dap.step_out)
      vim.keymap.set('n', '<F5>', dap.step_back)
      vim.keymap.set('n', '<F8>', dap.restart)
      vim.keymap.set('n', '<F9>', dap.terminate)

      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,
  },
}
