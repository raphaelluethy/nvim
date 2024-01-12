return {
    "mhartington/formatter.nvim",
    config = function()
        local util = require("formatter.util")

        require("formatter").setup({
            logging = true,
            log_level = vim.log.levels.WARN,
            filetype = {
                markdown = {
                    require("formatter.filetypes.markdown").denofmt,
                },
            },
        })
    end
}
