local create_user_command = vim.api.nvim_create_user_command

create_user_command(
  'InlayHintsToggle',
  require('raphaelluethy.config.inlay_utils').toggle_inlay_hints,
  { desc = 'Enable/Disable inlay hints on current buffer' }
)
create_user_command(
  'InlayHintsEnable',
  require('raphaelluethy.config.inlay_utils').enable_inlay_hints,
  { desc = 'Enable/Disable inlay hints on current buffer' }
)
create_user_command(
  'InlayHintsDisable',
  require('raphaelluethy.config.inlay_utils').disable_inlay_hints,
  { desc = 'Enable/Disable inlay hints on current buffer' }
)
create_user_command('OpenMarked', function()
  vim.cmd('silent !open -a "Marked 2" ' .. vim.fn.expand '%')
end, {
  desc = 'Open file in Marked 2',
})
