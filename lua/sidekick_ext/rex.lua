-- Thin wrapper around the `rex` CLI for talking to the Rex server.
local M = {}

function M.available()
	return vim.env.REX_SESSION ~= nil and vim.env.REX_BLOCK ~= nil and vim.fn.executable("rex") == 1
end

---@param argv string[]
---@return boolean ok, string out
local function run(argv)
	local res = vim.system(argv, { text = true }):wait(10000)
	if res.code ~= 0 then
		return false, vim.trim((res.stderr ~= "" and res.stderr) or res.stdout or "")
	end
	return true, res.stdout or ""
end

--- Call a session API method. Returns the decoded result or nil + error.
---@param method string
---@param args? table
---@return table?, string?
function M.call(method, args)
	local ok, out = run({ "rex", "api", "call", "-s", vim.env.REX_SESSION, method, vim.json.encode(args or vim.empty_dict()) })
	if not ok then
		return nil, out
	end
	local dok, decoded = pcall(vim.json.decode, out, { luanil = { object = true, array = true } })
	if not dok then
		return nil, "invalid JSON from rex: " .. out
	end
	return decoded
end

--- Call a method a block provides (e.g. `process`, `program_status`).
---@return table?, string?
function M.block_call(block_id, method)
	local ok, out = run({ "rex", "block", "call", "-s", vim.env.REX_SESSION, "-b", block_id, method })
	if not ok then
		return nil, out
	end
	local dok, decoded = pcall(vim.json.decode, out, { luanil = { object = true, array = true } })
	return dok and decoded or nil
end

--- The Rex window that holds this Neovim instance.
---@return string?
function M.window_id()
	local ok, out = run({ "rex", "block", "inspect", "-s", vim.env.REX_SESSION, vim.env.REX_BLOCK, "--json" })
	if not ok then
		return nil
	end
	local dok, info = pcall(vim.json.decode, out)
	return dok and info.block and info.block.window_id or nil
end

--- Terminal contents of a block (plain text, trimmed).
---@return string[]
function M.capture(block_id)
	local ok, out = run({ "rex", "capture", "-s", vim.env.REX_SESSION, "-b", block_id, "--trim" })
	if not ok then
		return { "capture failed: " .. out }
	end
	return vim.split(out, "\n", { plain = true })
end

--- Paste text into a block, optionally pressing Enter afterwards.
function M.paste(block_id, text, submit)
	local _, err = M.call("block.event", { block_id = block_id, event = { type = "paste", payload = { text = text } } })
	if err then
		return false, err
	end
	if submit then
		-- Give the TUI a moment to process the bracketed paste before submitting.
		vim.defer_fn(function()
			run({ "rex", "send-key", "-s", vim.env.REX_SESSION, "-b", block_id, "enter" })
		end, 150)
	end
	return true
end

return M
