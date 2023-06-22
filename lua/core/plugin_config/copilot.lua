-- highlight gray
-- highlight gray guifg=#5c6370
vim.cmd [[highlight CopilotSuggestion ctermfg=8 guifg=white guibg=#494f59]]
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""
-- vim.api.nvim_set_keymap("i", "<C-J>", "copilot#Accept('<CR>')", {
--     noremap = true,
--     silent = true,
--     expr = true,
--     replace_keycodes = false
-- })
