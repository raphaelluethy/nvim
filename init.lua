vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.appearance")
require("config.statusline")
require("config.lazy")
require("config.review").setup()
require("config.editor_context").setup()
