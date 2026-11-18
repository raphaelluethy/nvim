-- Run: nvim --headless -u NONE -l tests/completion.lua
local root = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
vim.opt.runtimepath:prepend(root)
vim.notify = function() end

local blink = require("plugins.blink")
local keys = {}
for _, key in ipairs(blink.keys) do
	keys[key[1]] = key[2]
end
blink.init()
local tab = vim.fn.maparg("<Tab>", "i", false, true).callback
local option_tab = keys["<M-Tab>"]
local toggle = keys["<leader>ue"]

local selected, ghost = false, true
local calls = {}
package.loaded["blink.cmp"] = {
	accept = function()
		table.insert(calls, "selected")
		return selected
	end,
	hide = function()
		table.insert(calls, "hide")
	end,
	select_and_accept = function()
		table.insert(calls, "first")
	end,
}
vim.lsp.inline_completion.get = function()
	table.insert(calls, "ghost")
	return ghost
end
local function expect(...)
	assert(vim.deep_equal(calls, { ... }), vim.inspect(calls))
	calls = {}
end

assert(tab() == "", "Tab should accept the suggestion by default")
expect("ghost", "hide")
option_tab()
expect("selected", "first")
ghost = false
assert(tab() == "<Tab>", "eager Tab should fall back when there is no suggestion")
expect("ghost")

toggle()
ghost = true
assert(tab() == "<Tab>", "lazy Tab should insert a tab")
expect()
selected = true
option_tab()
expect("selected")
selected = false
option_tab()
expect("selected", "ghost", "hide")
ghost = false
option_tab()
expect("selected", "ghost", "first")

keys["<leader>uc"]()
expect("hide")
assert(not blink.opts.enabled(), "the menu should be off")
ghost = true
option_tab()
expect("selected", "ghost", "hide")
toggle()
assert(tab() == "", "toggling back should restore eager Tab even with the menu off")
expect("ghost", "hide")
print("Completion tests passed")
