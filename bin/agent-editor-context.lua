-- Run by bin/agent-editor-context via `nvim -l`; see lua/config/editor_context.lua.
local format = arg[1] or "text"
local MAX_AGE = 12 * 3600

local cwd = vim.fs.normalize(vim.uv.cwd() or "")
local dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/nvim/editor-context"

local function inside(path, root)
	return path == root or path:sub(1, #root + 1) == root .. "/"
end

-- The most recent snapshot from a running Neovim that is about this directory
-- (same project either way round, or the file is under it).
local best
for name in vim.fs.dir(dir) do
	local pid = tonumber(name:match("^(%d+)%.json$"))
	if pid then
		local file = dir .. "/" .. name
		local alive = vim.uv.kill(pid, 0) == 0
		local f = alive and io.open(file, "r")
		if not alive then
			os.remove(file)
		elseif f then
			local ok, ctx = pcall(vim.json.decode, f:read("*a"))
			f:close()
			if
				ok
				and type(ctx) == "table"
				and type(ctx.file) == "string"
				and os.time() - (ctx.time or 0) < MAX_AGE
				and (inside(cwd, ctx.cwd) or inside(ctx.cwd, cwd) or inside(ctx.file, cwd))
				and (not best or ctx.time > best.time)
			then
				best = ctx
			end
		end
	end
end
if not best then
	return
end

local function display(path)
	if inside(path, cwd) and path ~= cwd then
		return path:sub(#cwd + 2)
	end
	return vim.fn.fnamemodify(path, ":~")
end

local out = {
	"The user is working in Neovim next to you. Editor state when they last left it (use it to resolve"
		.. ' references like "this file", "here" or "the selection"; ignore it when unrelated):',
	("- Current file: %s (line %d of %d, column %d)%s"):format(
		display(best.file),
		best.line,
		best.line_count,
		best.col,
		best.modified and " — has unsaved changes, the file on disk may differ" or ""
	),
}
local sel = best.selection
if type(sel) == "table" then
	if sel.text then
		out[#out + 1] = ("- Selected lines %d-%d:"):format(sel.from, sel.to)
		out[#out + 1] = "```" .. (best.filetype or "")
		out[#out + 1] = sel.text
		out[#out + 1] = "```"
	else
		out[#out + 1] = ("- Selected lines %d-%d (too long to include)"):format(sel.from, sel.to)
	end
end
local text = table.concat(out, "\n")

if format == "json" then
	io.write(vim.json.encode({
		hookSpecificOutput = { hookEventName = "UserPromptSubmit", additionalContext = text },
	}))
else
	io.write(text)
end
