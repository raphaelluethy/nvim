local lsp = require('lsp-zero').preset({})
local lspconfig = require('lspconfig')

vim.api.nvim_create_autocmd({'InsertEnter'}, {
    pattern = '*.ts,*.tsx,*.js,*.jsx,*.lua, *.rs',
    callback = function()
        if vim.bo.buftype ~= 'prompt' or not vim.tbl_contains({'TelescopePrompt'}, vim.bo.filetype) then
            vim.lsp.buf.inlay_hint(0, true)
        end
    end
})
vim.api.nvim_create_autocmd({'InsertLeave'}, {
    pattern = '*.ts,*.tsx,*.js,*.jsx,*.lua, *.rs',
    callback = function()
        if vim.bo.buftype ~= 'prompt' or not vim.tbl_contains({'TelescopePrompt'}, vim.bo.filetype) then
            vim.lsp.buf.inlay_hint(0, false)
        end
    end
})

lsp.ensure_installed({"tsserver", "eslint", "rust_analyzer", "lua_ls"})

lsp.set_preferences({
    suggest_lsp_servers = true,
    setup_servers_on_start = true,
    set_lsp_keymaps = true,
    configure_diagnostics = true,
    cmp_capabilities = true,
    manage_nvim_cmp = true,
    call_servers = "local",
    sign_icons = {
        error = "✘",
        warn = "▲",
        hint = "⚑",
        info = ""
    }
})

lsp.on_attach(function(client, bufnr)
    lsp.default_keymaps({
        buffer = bufnr
    })
end)

lsp.setup()

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = true,
    signs = true,
    update_in_insert = true
})

-- enable inline diagnostics
vim.diagnostic.config({
    virtual_text = true
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover, { focusable = false }
)

vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, keymap_opts)
vim.keymap.set("n", "K", vim.lsp.buf.hover, keymap_opts)
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, keymap_opts)
vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, keymap_opts)
vim.keymap.set("n", "gd", vim.lsp.buf.definition, keymap_opts)
vim.keymap.set('n', '<leader>fs', ':lua vim.lsp.buf.format({async = true})<CR> <BAR> <cmd>update<CR>') -- format on save
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)