-- Run: nvim --headless -u NONE -l tests/droid_ide.lua
local root = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
vim.opt.runtimepath:prepend(root)
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local file = dir .. "/example.lua"
vim.fn.writefile({ "a😀b", "second line" }, file)
vim.cmd.edit(file)
file = vim.api.nvim_buf_get_name(0)
vim.api.nvim_win_set_cursor(0, { 1, 5 })
local context = require("sidekick_ext.context")
context.setup()
local bridge = require("sidekick_ext.droid_ide")
bridge.setup()
local original_env = vim.env.FACTORY_VSCODE_MCP_PORT
local port = assert(bridge.port())
assert(bridge.port() == port, "Starting twice must reuse the server")
local lock = vim.fn.expand("~/.factory/ide/") .. port .. ".lock"
local metadata = vim.json.decode(table.concat(vim.fn.readfile(lock), "\n"))
assert(metadata.ideName == "Neovim" and metadata.pid == vim.fn.getpid())
assert(vim.env.FACTORY_VSCODE_MCP_PORT == tostring(port))
local command = require("sidekick_ext.agents").command("droid", {})
assert(command.cmd[1] == "droid" and command.env.FACTORY_VSCODE_MCP_PORT == tostring(port))
local buf = vim.api.nvim_get_current_buf()
local ns = vim.api.nvim_create_namespace("droid_ide_test")
function _G.DroidIDETest(action)
	if action == "change" then
		vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "changed" })
		vim.diagnostic.set(ns, buf, {
			{ lnum = 0, col = 5, end_col = 6, message = "test diagnostic", severity = 1, source = "test" },
		})
	elseif action == "clear" then
		vim.diagnostic.reset(ns, buf)
	elseif action == "terminal" then
		vim.cmd.vnew()
		vim.bo.buftype = "nofile"
	elseif action == "selection" then
		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		vim.api.nvim_feedkeys("Vj", "nx", false)
	elseif action == "empty" then
		vim.cmd.enew()
		vim.api.nvim_buf_delete(buf, { force = true })
	end
	vim.api.nvim_exec_autocmds("CursorMoved", {})
	return true
end
local addr = vim.v.servername ~= "" and vim.v.servername or vim.fn.serverstart()
local done, result
local job = vim.system({
	"python3",
	root .. "/tests/droid_ide.py",
	tostring(port),
	addr,
	file,
	vim.v.progpath,
}, { text = true }, function(res)
	result, done = res, true
end)
local finished = vim.wait(45000, function()
	return done
end, 10)
if not finished then
	job:kill(15)
end
bridge.stop()
bridge.stop()
assert(vim.fn.filereadable(lock) == 0, "Lock must be removed")
assert(vim.env.FACTORY_VSCODE_MCP_PORT == original_env, "Environment must be restored")
vim.fn.delete(dir, "rf")
if not finished or result.code ~= 0 then
	error(result and (result.stdout .. result.stderr) or "Protocol tests timed out")
end
io.stdout:write(result.stdout, result.stderr)
print("Lifecycle checks passed")
