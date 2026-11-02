-- Language servers and tools that Mason installs (lua/plugins/mason.lua) and
-- that lua/plugins/lsp.lua enables. Names are nvim-lspconfig names; an
-- optional `@version` suffix is only used for the Mason install.
local M = {}

M.lsps = {
	"clangd",
	"cssls",
	"emmet_language_server",
	"gopls",
	"html",
	"jsonls",
	"lua_ls",
	"oxfmt",
	"oxlint",
	"rust_analyzer",
	"tailwindcss",
	"tinymist",
	"tsc@7.1.0-beta",
	"ty",
}

M.tools = {
	"gofumpt",
	"goimports",
	"google-java-format",
	"ktfmt",
	"ruff",
	"stylua",
}

--- LSP config names without the `@version` suffix.
function M.lsp_names()
	return vim.tbl_map(function(name)
		return (name:gsub("@.*$", ""))
	end, M.lsps)
end

return M
