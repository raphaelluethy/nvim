local lsp = require('lsp-zero').preset({})
local lspconfig = require('lspconfig')

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

-- lspconfig.rust_analyzer.setup {
--     capabilities = lsp.capabilities,
--     on_attach = lsp.on_attach,
--     cmd = {"rustup", "run", "stable", "rust-analyzer"}
-- }

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

vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, keymap_opts)
vim.keymap.set("n", "K", vim.lsp.buf.hover, keymap_opts)
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, keymap_opts)
vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, keymap_opts)
vim.keymap.set("n", "gd", vim.lsp.buf.definition, keymap_opts)
vim.keymap.set('n', '<leader>fs', ':lua vim.lsp.buf.format({async = true})<CR> <BAR> <cmd>update<CR>') -- format on save
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
