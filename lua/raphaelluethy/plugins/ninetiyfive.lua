return {
  'https://github.com/ninetyfive-gg/ninetyfive.nvim',
  config = function()
    require('ninetyfive').setup {
      indexing = {
        mode = 'on', -- enables code indexing for better completions. 'ask' by default.
        cache_consent = false, -- optional, defaults to true
      },
    }
  end,
  version = false, -- we don't have versioning in the plugin yet
}
