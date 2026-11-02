-- Mason installs language servers, formatters and debug adapters. It loads
-- after startup (VeryLazy) or on :Mason; servers are enabled explicitly in
-- lua/plugins/lsp.lua and Mason's bin dir is put on PATH in config/options.lua.
return {
	"mason-org/mason.nvim",
	version = "*",
	event = "VeryLazy",
	cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonToolsInstall", "MasonToolsUpdate" },
	dependencies = {
		-- Stays on main: the `tsc` server mapping is not in a release yet.
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local servers = require("config.servers")
		require("mason").setup({ PATH = "skip" }) -- PATH is set in config/options.lua

		-- Only used for its lspconfig-name -> Mason-package mapping.
		require("mason-lspconfig").setup({
			ensure_installed = servers.lsps,
			automatic_enable = false,
		})

		if #vim.api.nvim_list_uis() > 0 then
			require("mason-tool-installer").setup({
				ensure_installed = servers.tools,
			})
		end
	end,
}
