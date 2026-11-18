-- Run: nvim --headless -u NONE -l tests/lsp.lua
local api = vim.api
local root = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
vim.opt.runtimepath:prepend(root)
vim.g.mapleader = " "

local lsp = vim.lsp
local highlight = lsp.protocol.Methods.textDocument_documentHighlight
local clients = {}
local requested, cleared = 0, {}
local picked
local jumped = false
lsp.buf.definition = function()
	jumped = true
end
local enabled_servers = {}
lsp.enable = function(names, enabled)
	for _, name in ipairs(type(names) == "table" and names or { names }) do
		enabled_servers[name] = enabled ~= false
	end
end
lsp.is_enabled = function(name)
	return enabled_servers[name] == true
end
lsp.get_client_by_id = function(id)
	return clients[id]
end
lsp.get_clients = function(filter)
	local result = {}
	for _, client in pairs(clients) do
		if client.buf == filter.bufnr and client:supports_method(filter.method, filter.bufnr) then
			result[#result + 1] = client
		end
	end
	return result
end
lsp.buf.document_highlight = function()
	requested = requested + 1
end
lsp.util.buf_clear_references = function(buf)
	cleared[buf] = (cleared[buf] or 0) + 1
end
package.preload["mini.extra"] = function()
	return {
		pickers = {
			lsp = function(opts)
				picked = opts.scope
			end,
		},
	}
end

require("plugins.lsp").config()
local toggle_copilot = vim.fn.maparg("<leader>ua", "n", false, true).callback
assert(lsp.is_enabled("copilot"), "Copilot should be enabled on startup")
local old_notify = vim.notify
vim.notify = function() end
toggle_copilot()
assert(not lsp.is_enabled("copilot"), "the toggle should disable the Copilot server")
assert(lsp.is_enabled("lua_ls"), "regular language servers should stay enabled")
toggle_copilot()
vim.notify = old_notify
assert(lsp.is_enabled("copilot"), "the toggle should re-enable the Copilot server")
local buf = api.nvim_get_current_buf()
local other = api.nvim_create_buf(true, false)
local function event(name, b, id)
	api.nvim_exec_autocmds(name, { buffer = b, data = id and { client_id = id } })
end
local function attach(b, id, supports)
	clients[id] = {
		id = id,
		buf = b,
		supports_method = function(_, method, bufnr)
			return supports and method == highlight and bufnr == b
		end,
	}
	event("LspAttach", b, id)
end
local function detach(b, id)
	-- Match Neovim: the detaching client is still visible during LspDetach.
	event("LspDetach", b, id)
	clients[id] = nil
end

attach(buf, 1, true)
attach(buf, 2, true)
attach(buf, 3, false)
attach(other, 4, true)
assert(not package.loaded["mini.extra"], "LSP attach should not load Mini")
vim.fn.maparg("gd", "n", false, true).callback()
assert(jumped and not package.loaded["mini.extra"], "gd should use native navigation without loading Mini")
local scopes = {
	gr = "references",
	gI = "implementation",
	gt = "type_definition",
	["<leader>o"] = "document_symbol",
	["<leader>ss"] = "workspace_symbol_live",
}
for key, scope in pairs(scopes) do
	picked = nil
	vim.fn.maparg(key, "n", false, true).callback()
	assert(picked == scope, key .. " should dispatch to the Mini " .. scope .. " picker")
end

event("CursorHold", buf)
event("CursorMoved", buf)
assert(requested == 1 and cleared[buf] == 1, "one set of highlight handlers per buffer")

detach(buf, 3)
detach(buf, 1)
event("CursorHoldI", buf)
assert(requested == 2, "highlights should remain while one supporting client is attached")
detach(other, 4)
assert(cleared[other] == 1 and cleared[buf] == 1, "detaching in a hidden buffer should only clear that buffer")
detach(buf, 2)
event("CursorHold", buf)
event("CursorMoved", buf)
assert(
	requested == 2 and cleared[buf] == 2,
	"the last supporting client should remove the handlers and clear highlights"
)

attach(buf, 5, true)
event("CursorHold", buf)
assert(requested == 3, "reattaching should restore the handlers")
local lines = {}
for i = 1, 3001 do
	lines[i] = ""
end
api.nvim_buf_set_lines(buf, 0, -1, false, lines)
event("CursorHold", buf)
assert(requested == 3, "large buffers should not request highlights")

print("LSP tests passed")
vim.cmd("qa!")
