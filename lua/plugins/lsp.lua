local goland_bin = vim.fn.expand("~/.config/zed-goland/bin/zed-goland")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = { enabled = false },
        goland = {
          mason = false,
          cmd = { goland_bin, "lsp" },
          filetypes = { "go", "gomod", "gowork" },
          root_markers = { "go.work", "go.mod", ".git" },
          init_options = {
            goSdkRoot = vim.NIL,
            goBuildTarget = {
              buildFlags = {},
              buildTags = "",
              env = vim.empty_dict(),
              clientEnv = vim.empty_dict(),
            },
            lazyIntentions = true,
            importInspectionProfile = true,
            intellijExtensions = true,
            projects = {},
            disableRocksDBWriteAheadLog = false,
            completion = { caseSensitivity = "firstLetter" },
          },
          before_init = function(params, config)
            if params.rootUri then
              config.init_options = config.init_options or {}
              config.init_options.buildTools = {
                [params.rootUri] = "gomodules-recursive-scan",
              }
            end
          end,
        },
        cssls = {},
        emmet_language_server = {},
        html = {},
        copilot = {
          on_init = function(client)
            client.server_capabilities.completionProvider = nil
          end,
          root_dir = function(bufnr, on_dir)
            if vim.bo[bufnr].buftype ~= "" then
              return
            end
            local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
            if name == "" or name:match("^%.env") or name:match("%.pem$") or name:match("%.key$") then
              return
            end
            on_dir(vim.fs.root(bufnr, ".git") or vim.fn.getcwd())
          end,
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "java", "kotlin" },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "google-java-format", "ktfmt" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["google-java-format"] = {
          prepend_args = { "--aosp", "--skip-reflowing-long-strings" },
        },
      },
      formatters_by_ft = {
        java = { "google-java-format" },
        kotlin = { "ktfmt" },
      },
    },
  },
}
