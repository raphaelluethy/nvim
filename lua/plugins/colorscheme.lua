return {
  {
    url = "git@github.com:raphaelluethy/monokai-pro-zed.git",
    name = "monokai-pro-zed",
    lazy = false,
    priority = 1000,
    opts = {
      dark = "monokai-pro-filter-spectrum-v3-no-italics",
      light = "monokai-pro-light-filter-sun-v3-no-italics",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "monokai-pro-zed",
    },
  },
}
