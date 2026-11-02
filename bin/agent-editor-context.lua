-- Run by bin/agent-editor-context via `nvim -l`; see lua/sidekick_ext/context.lua.
local format = arg[1] or "text"
local addr = os.getenv("SIDEKICK_NVIM") or os.getenv("NVIM") or ""
local mode = addr:match("^[%w.%-]+:%d+$") and "tcp" or "pipe"

local ok, chan = pcall(vim.fn.sockconnect, mode, addr, { rpc = true })
if not ok or chan == 0 then
	return
end
local ok2, text = pcall(vim.rpcrequest, chan, "nvim_exec_lua", [[
	local ok, ctx = pcall(require, "sidekick_ext.context")
	if ok then
		return ctx.text(...)
	end
]], { vim.uv.cwd() })
if not ok2 or type(text) ~= "string" or text == "" then
	return
end

if format == "json" then
	io.write(vim.json.encode({
		hookSpecificOutput = { hookEventName = "UserPromptSubmit", additionalContext = text },
	}))
else
	io.write(text)
end
