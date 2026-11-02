-- Ask a cheap model (via `opencode run`, tools disabled, prompt on stdin) to
-- group hunks into semantic change groups. Token diet: 1 context line per
-- hunk, bodies capped, lockfiles/generated/sensitive files sent as headers
-- only, secret-looking values redacted, and refreshes only send the new
-- hunks ("assign") instead of the whole diff. Results are cached per
-- hunk-set hash.
local M = {}

M.config = {
	models = {
		{ id = "claude-agent/haiku", label = "Haiku 5.5" },
		{ id = "openai/gpt-6.1-terra-fast", label = "GPT-6.1 Terra fast" },
	},
	model = 1, -- index into `models`, or a model id string
	timeout = 180000,
	max_hunk_lines = 60, -- body lines per hunk shown to the model
	max_new_file_lines = 40, -- head of an added/untracked file
	max_chars = 90000, -- whole prompt budget
	-- Files whose bodies are never sent (header + line counts only).
	skip_body = {
		"%.lock$",
		"lazy%-lock%.json$",
		"package%-lock%.json$",
		"pnpm%-lock%.yaml$",
		"yarn%.lock$",
		"Cargo%.lock$",
		"%.min%.%w+$",
		"%.map$",
		"%.svg$",
		"%.snap$",
		"%.ipynb$",
	},
	-- Files that may hold credentials: header only, never the body.
	sensitive = { "%.env", "%.pem$", "%.key$", "%.p12$", "%.pfx$", "%.jks$", "%.kdbx$", "id_rsa", "id_ed25519", "credential", "secret", "%.netrc$", "%.npmrc$", "%.pypirc$", "service%-account" },
	redact = true, -- mask key/token/password values in the lines that are sent
	cache_dir = vim.fn.stdpath("cache") .. "/sidekick-semantic",
}

---@class sidekick_ext.sem.Group
---@field id integer
---@field title string
---@field kind string feat|fix|refactor|test|docs|chore|style|build|perf|new|other
---@field summary string
---@field hunks string[] hunk hashes
---@field notes table<string, string> hash -> one-line note

M.KINDS = { feat = true, fix = true, refactor = true, test = true, docs = true, chore = true, style = true, build = true, perf = true }

local SYSTEM = table.concat({
	"You are a senior code reviewer. You receive hunks of a code diff and group them into semantic change",
	"groups (changelists), like the AI change grouping in JetBrains IDEs. Each group is one coherent intent",
	"(a feature, a fix, a refactor, test or doc updates, config churn). Hunks from different files that serve",
	"the same intent belong together; unrelated hunks in one file belong to different groups. Prefer 2-7",
	"groups; never one group per hunk unless they truly differ. Order groups by importance (behavior changes",
	"first, noise like formatting or lockfiles last). Hunk bodies may be truncated or omitted; use the file",
	"path, header and line counts then. Answer with ONE JSON object and nothing else: no prose, no fences.",
}, " ")

local SCHEMA = [[{"groups":[{"title":"short imperative title, max 60 chars","kind":"feat|fix|refactor|test|docs|chore|style|build|perf","summary":"2-4 plain sentences: what changes and why, for a reviewer","hunks":[1,2],"notes":{"1":"one line: what this hunk does"}}]}]]

local ASSIGN_SCHEMA = [[{"assign":[{"group":1,"hunks":[7],"notes":{"7":"one line"}}],"groups":[{"title":"...","kind":"...","summary":"...","hunks":[8],"notes":{"8":"one line"}}]}]]

local function model_index()
	local m = M.config.model
	if type(m) == "string" then
		for i, entry in ipairs(M.config.models) do
			if entry.id == m or entry.label == m then
				return i
			end
		end
		return 1
	end
	return M.config.models[m] and m or 1
end

function M.model()
	return M.config.models[model_index()]
end

function M.cycle_model()
	M.config.model = model_index() % #M.config.models + 1
	return M.model()
end

---------------------------------------------------------------------------
-- Prompt building

local function matches(path, patterns)
	local lower = path:lower()
	for _, pat in ipairs(patterns) do
		if lower:find(pat) then
			return true
		end
	end
	return false
end

local SECRET_WORDS = { "api[_%-]?key", "secret", "token", "passw", "pwd", "authorization", "bearer", "private[_%-]?key", "client[_%-]?secret", "access[_%-]?key" }
local SECRET_SHAPES = { "sk%-[%w%-_]+", "ghp_%w+", "gho_%w+", "github_pat_%w+", "xox[abp]%-[%w%-]+", "AKIA[0-9A-Z]+", "AIza[%w%-_]+", "eyJ[%w%-_]+%.[%w%-_]+%.[%w%-_]+" }

--- Mask the value part of key/token/password assignments and known token shapes.
function M.redact(line)
	local lower = line:lower()
	for _, word in ipairs(SECRET_WORDS) do
		local s, e = lower:find(word .. "[%w_%-%.]*%s*[:=]%s*", 1)
		if s then
			local rest = line:sub(e + 1)
			if rest:match("^[\"']?[%w%-%._/+=]+") then
				return line:sub(1, e) .. "«redacted»"
			end
		end
	end
	for _, shape in ipairs(SECRET_SHAPES) do
		line = line:gsub(shape, "«redacted»")
	end
	if line:find("PRIVATE KEY%-%-%-%-%-") then
		return "«redacted private key»"
	end
	return line
end

local function body(h, max_lines)
	if matches(h.file, M.config.sensitive) then
		return ("(body omitted: sensitive file, +%d -%d)"):format(h.adds, h.dels)
	end
	if matches(h.file, M.config.skip_body) then
		return ("(body omitted: lockfile/generated, +%d -%d)"):format(h.adds, h.dels)
	end
	local lines = h.lines
	if h.status == "A" or h.status == "??" then
		max_lines = math.min(max_lines, M.config.max_new_file_lines)
	end
	local out, omitted = {}, 0
	if #lines <= max_lines then
		out = lines
	else
		local head = math.max(1, max_lines - 12)
		for i = 1, head do
			out[#out + 1] = lines[i]
		end
		out[#out + 1] = ("… %d lines omitted …"):format(#lines - head - 12)
		for i = #lines - 11, #lines do
			out[#out + 1] = lines[i]
		end
		omitted = 1
	end
	if M.config.redact then
		local red = {}
		for i, l in ipairs(out) do
			red[i] = M.redact(l)
		end
		out = red
	end
	local text = table.concat(out, "\n")
	-- Drop indentation beyond the first column of the diff marker: it costs
	-- tokens and the model does not need it.
	text = text:gsub("\n([%+%- ])[ \t]+", "\n%1 "):gsub("^([%+%- ])[ \t]+", "%1 ")
	return text, omitted
end

local function status_word(h)
	return h.status == "??" and "untracked" or h.status == "A" and "added" or h.status == "D" and "deleted" or h.status == "R" and ("renamed from " .. (h.old_path or "?")) or "modified"
end

local function hunk_sections(hunks, max_lines)
	local out = {}
	for _, h in ipairs(hunks) do
		out[#out + 1] = ("### Hunk %d · %s (%s) %s"):format(h.id, h.file, status_word(h), h.header)
		out[#out + 1] = body(h, max_lines)
		out[#out + 1] = ""
	end
	return table.concat(out, "\n")
end

local function fit(build)
	local max_lines = M.config.max_hunk_lines
	local p = build(max_lines)
	while #p > M.config.max_chars and max_lines > 6 do
		max_lines = math.floor(max_lines / 2)
		p = build(max_lines)
	end
	return p
end

--- Full grouping prompt.
function M.prompt(hunks, root)
	return fit(function(max_lines)
		return table.concat({
			("Repository: %s. %d hunks."):format(vim.fs.basename(root), #hunks),
			"Group ALL hunks below. Every hunk id must appear in exactly one group. Only use ids that exist.",
			"Output (strict JSON): " .. SCHEMA,
			"",
			hunk_sections(hunks, max_lines),
		}, "\n")
	end)
end

--- Incremental prompt: existing groups as one line each, only the new hunks in full.
function M.assign_prompt(new_hunks, groups, root)
	local glines = {}
	for i, g in ipairs(groups) do
		glines[#glines + 1] = ("G%d [%s] %s — %s"):format(i, g.kind, g.title, g.summary:sub(1, 200))
	end
	return fit(function(max_lines)
		return table.concat({
			("Repository: %s. The diff was already grouped; %d new hunks appeared."):format(vim.fs.basename(root), #new_hunks),
			"Assign each new hunk to an existing group (by its G number) when it serves the same intent,",
			"otherwise create new groups. Every new hunk id must appear exactly once.",
			"Output (strict JSON): " .. ASSIGN_SCHEMA,
			"",
			"Existing groups:",
			table.concat(glines, "\n"),
			"",
			hunk_sections(new_hunks, max_lines),
		}, "\n")
	end)
end

---------------------------------------------------------------------------
-- opencode runner

--- Extract the text parts from `opencode run --format json` (one JSON event per line).
local function response_text(stdout)
	local order, texts, err = {}, {}, nil
	for _, line in ipairs(vim.split(stdout, "\n", { trimempty = true })) do
		local ok, ev = pcall(vim.json.decode, line)
		if ok and type(ev) == "table" then
			local part = ev.part or {}
			if ev.type == "text" and type(part.text) == "string" then
				local key = part.id or tostring(#order + 1)
				if not texts[key] then
					order[#order + 1] = key
				end
				texts[key] = part.text
			elseif ev.type == "error" then
				err = vim.inspect(ev.error or ev)
			end
		end
	end
	local parts = {}
	for _, k in ipairs(order) do
		parts[#parts + 1] = texts[k]
	end
	return table.concat(parts, ""), err
end

local function extract_json(text)
	text = text:gsub("```%w*", "")
	local s, e = text:find("{"), nil
	for i = #text, 1, -1 do
		if text:sub(i, i) == "}" then
			e = i
			break
		end
	end
	if not s or not e or e < s then
		return nil
	end
	local ok, data = pcall(vim.json.decode, text:sub(s, e), { luanil = { object = true, array = true } })
	return ok and type(data) == "table" and data or nil
end

--- Run one prompt through opencode; `cb(err, json)` on the main loop.
---@return vim.SystemObj
function M.run(prompt, root, cb)
	local agent = {
		sk_grouper = {
			mode = "primary",
			description = "Groups diff hunks into semantic changelists (JSON only)",
			tools = { ["*"] = false },
			prompt = SYSTEM,
		},
	}
	local cmd = { "opencode", "run", "--standalone", "--model", M.model().id, "--agent", "sk_grouper", "--format", "json" }
	return vim.system(cmd, {
		text = true,
		cwd = root,
		stdin = prompt,
		timeout = M.config.timeout,
		env = { OPENCODE_CONFIG_CONTENT = vim.json.encode({ agent = agent }) },
	}, function(res)
		vim.schedule(function()
			if res.code ~= 0 and (res.stdout or "") == "" then
				return cb(("opencode exited with %d: %s"):format(res.code, vim.trim(res.stderr or "")))
			end
			local text, err = response_text(res.stdout or "")
			local data = extract_json(text)
			if not data then
				return cb("model returned no JSON" .. (err and (": " .. err) or "") .. (text ~= "" and ("\n" .. text:sub(1, 300)) or ""))
			end
			cb(nil, data)
		end)
	end)
end

---------------------------------------------------------------------------
-- Normalisation (model ids -> hunk hashes)

local function read_group(g, by_id, used)
	local group = {
		title = type(g.title) == "string" and vim.trim(g.title) or "Untitled",
		kind = M.KINDS[g.kind] and g.kind or "other",
		summary = type(g.summary) == "string" and vim.trim(g.summary) or "",
		hunks = {},
		notes = {},
	}
	for _, id in ipairs(type(g.hunks) == "table" and g.hunks or {}) do
		id = tonumber(id)
		local h = id and by_id[id]
		if h and not used[h.hash] then
			used[h.hash] = true
			group.hunks[#group.hunks + 1] = h.hash
			local note = type(g.notes) == "table" and (g.notes[tostring(id)] or g.notes[id])
			if type(note) == "string" then
				group.notes[h.hash] = vim.trim(note)
			end
		end
	end
	return group
end

local function leftovers(hunks, used)
	local rest = {}
	for _, h in ipairs(hunks) do
		if not used[h.hash] then
			rest[#rest + 1] = h.hash
		end
	end
	return rest
end

local function renumber(groups)
	for i, g in ipairs(groups) do
		g.id = i
	end
	return groups
end

--- Full grouping answer → groups. Every hunk ends up in exactly one group.
---@return sidekick_ext.sem.Group[]
function M.normalize(data, hunks)
	local by_id, used, groups = {}, {}, {}
	for _, h in ipairs(hunks) do
		by_id[h.id] = h
	end
	for _, g in ipairs(type(data.groups) == "table" and data.groups or {}) do
		if type(g) == "table" then
			local group = read_group(g, by_id, used)
			if #group.hunks > 0 then
				groups[#groups + 1] = group
			end
		end
	end
	local rest = leftovers(hunks, used)
	if #rest > 0 then
		groups[#groups + 1] = { title = "Other changes", kind = "other", summary = "Hunks the model did not assign.", hunks = rest, notes = {} }
	end
	return renumber(groups)
end

--- Assignment answer → existing groups extended + new groups appended.
---@return sidekick_ext.sem.Group[]
function M.normalize_assign(data, new_hunks, groups)
	local by_id, used = {}, {}
	for _, h in ipairs(new_hunks) do
		by_id[h.id] = h
	end
	for _, a in ipairs(type(data.assign) == "table" and data.assign or {}) do
		local target = type(a) == "table" and groups[tonumber(a.group) or 0]
		if target then
			local g = read_group(a, by_id, used)
			vim.list_extend(target.hunks, g.hunks)
			for hash, note in pairs(g.notes) do
				target.notes[hash] = note
			end
		end
	end
	for _, g in ipairs(type(data.groups) == "table" and data.groups or {}) do
		if type(g) == "table" then
			local group = read_group(g, by_id, used)
			if #group.hunks > 0 then
				groups[#groups + 1] = group
			end
		end
	end
	local rest = leftovers(new_hunks, used)
	if #rest > 0 then
		groups[#groups + 1] = { title = "New changes", kind = "new", summary = "Not assigned by the model. Press r to regroup.", hunks = rest, notes = {} }
	end
	return renumber(groups)
end

--- Group all hunks. `cb(err, groups)`.
function M.group(hunks, root, cb)
	if #hunks == 0 then
		return cb(nil, {})
	end
	return M.run(M.prompt(hunks, root), root, function(err, data)
		if err then
			return cb(err)
		end
		cb(nil, M.normalize(data, hunks))
	end)
end

--- Assign only `new_hunks` into `groups` (mutated). `cb(err, groups)`.
function M.assign(new_hunks, groups, root, cb)
	if #new_hunks == 0 then
		return cb(nil, groups)
	end
	if #groups == 0 then
		return M.group(new_hunks, root, cb)
	end
	return M.run(M.assign_prompt(new_hunks, groups, root), root, function(err, data)
		if err then
			return cb(err)
		end
		cb(nil, M.normalize_assign(data, new_hunks, groups))
	end)
end

---------------------------------------------------------------------------
-- Cache: one file per (repo, hunk-set hash)

local function cache_file(root, set_hash)
	return ("%s/%s-%s.json"):format(M.config.cache_dir, vim.fn.sha256(root):sub(1, 12), set_hash:sub(1, 24))
end

---@return sidekick_ext.sem.Group[]?
function M.cache_get(root, set_hash)
	local f = io.open(cache_file(root, set_hash), "r")
	if not f then
		return nil
	end
	local ok, data = pcall(vim.json.decode, f:read("*a"), { luanil = { object = true, array = true } })
	f:close()
	return ok and type(data) == "table" and data.groups or nil
end

local function write(path, groups)
	local f = io.open(path, "w")
	if f then
		f:write(vim.json.encode({ groups = groups, model = M.model().id, time = os.time() }))
		f:close()
	end
end

function M.cache_put(root, set_hash, groups)
	vim.fn.mkdir(M.config.cache_dir, "p")
	write(cache_file(root, set_hash), groups)
	-- Also remember the newest grouping per repo, so a later session with a
	-- changed diff only sends the new hunks to the model.
	write(cache_file(root, "latest"), groups)
end

---@return sidekick_ext.sem.Group[]?
function M.latest_get(root)
	return M.cache_get(root, "latest")
end

return M
