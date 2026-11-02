-- Collect the local changes (staged + unstaged + untracked, i.e. everything
-- the review panel shows) as a flat list of hunks. Hunk hashes are content
-- based (file + body, no line numbers), so a hunk keeps its identity while
-- code above it moves.
local M = {}

---@class sidekick_ext.sem.Hunk
---@field id integer 1-based, stable within one collection
---@field file string repo-relative path (new side)
---@field old_path? string
---@field status string "M"|"A"|"D"|"R"|"??"
---@field old_start integer
---@field old_count integer
---@field new_start integer
---@field new_count integer
---@field header string the `@@` line (incl. function context)
---@field lines string[] body lines with their +/-/space prefix
---@field hash string
---@field adds integer
---@field dels integer

M.config = {
	context = 1, -- diff context lines; 1 keeps prompts small
	max_untracked_bytes = 256 * 1024,
}

local function git(root, args, cb)
	vim.system(vim.list_extend({ "git", "-C", root, "--no-optional-locks" }, args), { text = true }, function(res)
		vim.schedule(function()
			if res.code ~= 0 then
				return cb((res.stderr ~= "" and vim.trim(res.stderr)) or ("git " .. args[1] .. " failed"))
			end
			cb(nil, res.stdout or "")
		end)
	end)
end

--- `git status --porcelain -z` → { [path] = { x = index, y = worktree, old_path? } }
local function parse_status(out)
	local map, entries, i = {}, vim.split(out, "\0", { plain = true, trimempty = true }), 1
	while i <= #entries do
		local line = entries[i]
		if #line >= 3 then
			local x, y, path = line:sub(1, 1), line:sub(2, 2), line:sub(4)
			local old
			if x == "R" or x == "C" or y == "R" or y == "C" then
				i = i + 1
				old = entries[i]
			end
			map[path] = { x = x, y = y, old_path = old }
		end
		i = i + 1
	end
	return map
end

local function strip_prefix(p)
	if p == "/dev/null" then
		return nil
	end
	p = p:gsub("^[ab]/", "")
	if p:sub(1, 1) == '"' then
		p = p:sub(2, -2):gsub("\\(%d%d%d)", function(o)
			return string.char(tonumber(o, 8))
		end)
	end
	return p
end

local function finish(h)
	h.adds, h.dels = 0, 0
	for _, l in ipairs(h.lines) do
		local c = l:sub(1, 1)
		if c == "+" then
			h.adds = h.adds + 1
		elseif c == "-" then
			h.dels = h.dels + 1
		end
	end
	h.hash = vim.fn.sha256(h.file .. "\n" .. table.concat(h.lines, "\n"))
end

--- Parse `git diff` unified output into hunks.
---@return sidekick_ext.sem.Hunk[]
local function parse_diff(out)
	local hunks, file, hunk = {}, nil, nil
	local function close()
		if hunk then
			finish(hunk)
			hunks[#hunks + 1] = hunk
			hunk = nil
		end
	end
	for _, line in ipairs(vim.split(out, "\n", { plain = true })) do
		if line:match("^diff %-%-git ") then
			close()
			file = { status = "M" }
		elseif not file then
			-- skip preamble
		elseif line:match("^rename from ") then
			file.old_path = strip_prefix(line:sub(13))
			file.status = "R"
		elseif line:match("^new file mode") then
			file.status = "A"
		elseif line:match("^deleted file mode") then
			file.status = "D"
		elseif line:match("^Binary files") then
			file.binary = true
		elseif line:match("^%-%-%- ") then
			close()
			file.a = strip_prefix(line:sub(5))
		elseif line:match("^%+%+%+ ") then
			file.b = strip_prefix(line:sub(5))
		elseif line:match("^@@ ") then
			close()
			local os, oc, ns, nc = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
			hunk = {
				file = file.b or file.a,
				old_path = file.old_path or (file.a ~= file.b and file.a or nil),
				status = file.status,
				old_start = tonumber(os) or 0,
				old_count = oc ~= "" and tonumber(oc) or 1,
				new_start = tonumber(ns) or 0,
				new_count = nc ~= "" and tonumber(nc) or 1,
				header = line,
				lines = {},
			}
		elseif hunk then
			local c = line:sub(1, 1)
			if c == "+" or c == "-" or c == " " then
				hunk.lines[#hunk.lines + 1] = line
			end
			-- "\ No newline at end of file" and anything else is dropped
		end
	end
	close()
	return hunks
end

--- One synthetic add-everything hunk per untracked text file.
local function untracked_hunks(root, status)
	local ret = {}
	for path, st in pairs(status) do
		if st.x == "?" and st.y == "?" then
			local abs = vim.fs.joinpath(root, path)
			local stat = vim.uv.fs_stat(abs)
			if stat and stat.type == "file" and stat.size <= M.config.max_untracked_bytes then
				local ok, content = pcall(vim.fn.readfile, abs, "b")
				if ok and not table.concat(content, "\n", 1, math.min(#content, 50)):find("\0", 1, true) then
					if content[#content] == "" then
						content[#content] = nil
					end
					if #content == 0 then
						goto continue
					end
					local h = { file = path, status = "??", old_start = 0, old_count = 0, new_start = 1, new_count = #content, lines = {} }
					h.header = ("@@ -0,0 +1,%d @@"):format(#content)
					for _, l in ipairs(content) do
						h.lines[#h.lines + 1] = "+" .. l
					end
					finish(h)
					ret[#ret + 1] = h
				end
			end
		end
		::continue::
	end
	return ret
end

--- Collect all hunks of the working tree vs HEAD (plus untracked files).
---@param root string repo root
---@param cb fun(err?: string, hunks?: sidekick_ext.sem.Hunk[])
function M.collect(root, cb)
	git(root, { "status", "--porcelain=v1", "-z", "--untracked-files=all", "-M" }, function(err, out)
		if err then
			return cb(err)
		end
		local status = parse_status(out)
		git(root, { "diff", "HEAD", "--no-color", "--no-ext-diff", "--find-renames", "-U" .. M.config.context, "--" }, function(derr, dout)
			if derr then
				return cb(derr)
			end
			local hunks = parse_diff(dout)
			vim.list_extend(hunks, untracked_hunks(root, status))
			table.sort(hunks, function(a, b)
				return a.file == b.file and a.new_start < b.new_start or a.file < b.file
			end)
			for i, h in ipairs(hunks) do
				h.id = i
			end
			cb(nil, hunks)
		end)
	end)
end

--- Hash of the whole hunk set (cache key for a grouping).
function M.set_hash(hunks)
	local keys = {}
	for _, h in ipairs(hunks) do
		keys[#keys + 1] = h.hash
	end
	table.sort(keys)
	return vim.fn.sha256(table.concat(keys, ""))
end

return M
