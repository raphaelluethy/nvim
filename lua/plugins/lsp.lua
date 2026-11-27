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
