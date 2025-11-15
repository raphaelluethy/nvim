return {
  -- Main LSP Configuration
  "neovim/nvim-lspconfig",
  event = { "BufReadPost" },
  cmd = { "LspInfo", "LspInstall", "LspUninstall", "Mason" },
  dependencies = {
    -- LSP installer plugins
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- Integrate blink / cmp w/ LSP
    "hrsh7th/cmp-nvim-lsp",
    -- Progress indicator for LSP
    { "j-hui/fidget.nvim" },
  },
  config = function()
    -- Get default capabilities (can be extended by nvim-cmp if available)
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok_cmp then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    -- LspAttach: Runs when an LSP client attaches to a buffer
    -- Sets up keymaps, document highlighting, and inlay hints
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("raphaelluethy-lsp-attach", {
        clear = true,
      }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, keys, func, {
            buffer = event.buf,
            desc = "LSP: " .. desc,
          })
        end

        -- Navigation keymaps
        map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
        map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

        -- Symbol search keymaps
        map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
        map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        -- Code actions
        map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

        local client = vim.lsp.get_client_by_id(event.data.client_id)

        -- Document highlighting: highlights all references to symbol under cursor
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup("raphaelluethy-lsp-highlight", {
            clear = false,
          })

          -- Set custom highlight colors for LSP references
          vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#3a3a3a" })
          vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#3a3a3a" })
          vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#3a3a3a" })

          -- CursorHold/CursorHoldI: Highlight references when cursor stops moving
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = function()
              -- Only enable for smaller files to avoid performance issues
              if vim.api.nvim_buf_line_count(event.buf) <= 3000 then
                vim.lsp.buf.document_highlight()
              end
            end,
          })

          -- CursorMoved/CursorMovedI: Clear highlights when cursor moves
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          -- LspDetach: Clean up highlights when LSP detaches
          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("raphaelluethy-lsp-detach", {
              clear = true,
            }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({
                group = "raphaelluethy-lsp-highlight",
                buffer = event2.buf,
              })
            end,
          })
        end

        -- Inlay hints: toggle keymap if supported
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({
              bufnr = event.buf,
            }))
          end, "[T]oggle Inlay [H]ints")
        end
      end,
    })

    -- LSP servers and their specific settings
    local servers = {
      clangd = {},
      gopls = {},
      rust_analyzer = {},
	  -- handles by ts-tools.lua
      -- vtsls = {},
      -- ts_ls = {},
	  ty = {},
      emmet_ls = {
        filetypes = {
          "css",
          "eruby",
          "html",
          "javascript",
          "javascriptreact",
          "less",
          "pass",
          "scss",
          "svelte",
          "pug",
          "typescriptreact",
          "vue",
        },
      },
      tinymist = {
        offset_encoding = "utf-8",
      },

      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = "Replace",
            },
            diagnostics = {
              -- Define global variables that LuaLS will recognize
              globals = { "vim", "Snacks" },
              disable = { "missing-fields" },
            },
          },
        },
      },
    }

    -- List of server names for mason-lspconfig & mason-tool-installer
    local server_names = vim.tbl_keys(servers or {})

    -- Setup Mason for LSP and tool installation
    require("mason").setup()

    -- Configure tools to ensure installation (LSP servers + extra tools)
    local ensure_tools = {}
    vim.list_extend(ensure_tools, server_names)
    vim.list_extend(ensure_tools, {
      "stylua", -- Lua formatter
    })

    require("mason-tool-installer").setup({
      ensure_installed = ensure_tools,
    })

    -- Setup LSP servers with Mason
    require("mason-lspconfig").setup({
      ensure_installed = server_names,
      automatic_installation = true,
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          -- Merge capabilities, allowing server-specific overrides
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          require("lspconfig")[server_name].setup(server)
        end,
      },
    })
  end,
}

