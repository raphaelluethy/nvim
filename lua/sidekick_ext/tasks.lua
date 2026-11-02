-- Hidden sidekick tasks: run an AI CLI in a minimized Rex floating layer and
-- bring it back later from a picker. The layers are panels.nvim panels
-- labelled "sk-task:<tool>"; Rex is the source of truth, so tasks survive
-- Neovim restarts (panels.discover() finds them again).
local Panels = require("panels")
local Rex = require("panels.rex")

local M = {}

local PREFIX = "sk-task:"

local Agents = require("sidekick_ext.agents")

M.config = {
	size = { width = 0.92, height = 0.92 }, -- fractions of the Rex window
}

local state_file = vim.fn.stdpath("state") .. "/sidekick-tasks.json"

---@class sidekick_ext.TaskMeta
---@field tool string
---@field prompt string
---@field cwd string
---@field created integer

---@return table<string, sidekick_ext.TaskMeta>
local function load_meta()
	local f = io.open(state_file, "r")
	if not f then
		return {}
	end
	local ok, data = pcall(vim.json.decode, f:read("*a"))
	f:close()
	return ok and type(data) == "table" and data or {}
end

local function save_meta(meta)
	vim.fn.mkdir(vim.fn.fnamemodify(state_file, ":h"), "p")
	local f = io.open(state_file, "w")
	if f then
		f:write(vim.json.encode(next(meta) and meta or vim.empty_dict()))
		f:close()
	end
end

--- Do tasks run in Rex? The "tasks" switch (panels group "sk-task",
--- lua/plugins/panels.lua); outside Rex they are Neovim agent sessions.
function M.rex()
	return Panels.resolve({ label = PREFIX .. "task" }).backend == "rex"
end

local function check()
	if not Rex.available() then
		vim.notify("sidekick tasks need Neovim to run inside Rex", vim.log.levels.ERROR)
		return false
	end
	return true
end

local function title_of(prompt)
	local line = vim.trim((prompt:match("[^\n]*%S[^\n]*") or prompt))
	line = line:gsub("%s+", " ")
	return #line > 48 and (line:sub(1, 47) .. "…") or line
end

---@class sidekick_ext.Task
---@field panel panels.Panel
---@field block_id string key of the task's metadata
---@field tool string
---@field title string
---@field hidden boolean
---@field meta? sidekick_ext.TaskMeta

---@param p panels.Panel
---@param meta table<string, sidekick_ext.TaskMeta>
---@return sidekick_ext.Task
local function task_of(p, meta)
	return {
		panel = p,
		block_id = p.block_id,
		tool = p.label:sub(#PREFIX + 1),
		title = p.title or "",
		hidden = not p:is_open(),
		meta = meta[p.block_id],
	}
end

--- All live tasks in this Rex session, oldest first.
---@return sidekick_ext.Task[]
function M.list()
	if not check() then
		return {}
	end
	local meta = load_meta()
	local live, ret = {}, {}
	for _, p in ipairs(Panels.discover({ label_prefix = PREFIX })) do
		live[p.block_id] = true
		ret[#ret + 1] = task_of(p, meta)
	end
	-- Drop metadata for tasks that no longer exist.
	local pruned = false
	for id in pairs(meta) do
		if not live[id] then
			meta[id], pruned = nil, true
		end
	end
	if pruned then
		save_meta(meta)
	end
	table.sort(ret, function(a, b)
		return (a.meta and a.meta.created or 0) < (b.meta and b.meta.created or 0)
	end)
	return ret
end

--- Short status: exited / closed / blocked / working / running.
---@param task sidekick_ext.Task
function M.status(task)
	local state, code = task.panel:status()
	if state == "exited" then
		return "exited " .. tostring(code)
	elseif state ~= "running" then
		return state
	end
	-- What the agent itself reports (Rex program status), e.g. working / blocked.
	local ps = Rex.block_call(task.block_id, "program_status")
	local rec = ps and ps.records and ps.records[#ps.records]
	if type(rec) == "table" then
		local s = rec.status or rec.state
		if type(s) == "string" and s ~= "" then
			return s
		end
	end
	return "running"
end

---@class sidekick_ext.NewTaskOpts
---@field prompt string
---@field tool? string
---@field sel? sidekick_ext.Selection model / mode / effort (defaults to the saved one)
---@field show? boolean start visible instead of hidden
---@field cwd? string

---@param opts sidekick_ext.NewTaskOpts
---@return sidekick_ext.Task?
function M.new(opts)
	if not check() then
		return
	end
	local tool = opts.tool or Agents.last_tool()
	if not Agents.specs[tool] then
		vim.notify("sidekick tasks: unknown tool " .. tool, vim.log.levels.ERROR)
		return
	end
	local sel = opts.sel or Agents.selection(tool)
	local cwd = opts.cwd or vim.fn.getcwd()
	local title = title_of(opts.prompt)
	local panel = Panels.open({
		backend = "rex",
		cmd = Agents.cmd(tool, sel, opts.prompt),
		cwd = cwd,
		title = title,
		label = PREFIX .. tool,
		size = M.config.size,
		hidden = not opts.show,
		focus = opts.show == true,
	})
	if not panel then
		return -- panels.nvim already reported the error
	end
	Agents.set_last_tool(tool)
	local meta = load_meta()
	meta[panel.block_id] = { tool = tool, prompt = opts.prompt, cwd = cwd, created = os.time() }
	save_meta(meta)
	vim.notify(("%s task started%s: %s"):format(tool, opts.show and "" or " (hidden)", title))
	return task_of(panel, meta)
end

---@param task sidekick_ext.Task
function M.show(task)
	task.panel:show({ focus = true })
end

---@param task sidekick_ext.Task
function M.hide(task)
	task.panel:hide()
end

function M.hide_all()
	if not M.rex() then
		return require("sidekick_ext.sessions").hide_all()
	end
	for _, t in ipairs(M.list()) do
		if not t.hidden then
			M.hide(t)
		end
	end
end

---@param task sidekick_ext.Task
function M.kill(task)
	task.panel:close()
end

--- Send a follow-up message to a running task without showing it.
---@param task sidekick_ext.Task
---@param text string
function M.send(task, text)
	local ok, err = task.panel:send(text, true)
	if not ok then
		vim.notify("sidekick task: " .. tostring(err), vim.log.levels.ERROR)
	end
end

--- Submit using the backend selected in the Lua configuration.
function M.submit(opts)
	if M.rex() then
		return M.new(opts)
	end
	return require("sidekick_ext.sessions").new(opts)
end

--- Pick an agent and submit a task. Tasks start in the background by default;
--- the task picker can show their terminal later.
---@param opts? { tool?: string, show?: boolean } show = <C-s> starts visible
function M.prompt(opts)
	opts = opts or {}
	local actions = {
		{
			label = "Submit",
			run = function(text, tool, sel)
				M.submit({ prompt = text, tool = tool, sel = sel, show = opts.show == true })
			end,
		},
	}
	return Agents.form({ title = "Submit task", tool = opts.tool, actions = actions })
end

--- Telescope picker over all tasks. Preview shows the agent's screen.
function M.pick()
	if not M.rex() then
		return require("sidekick_ext.sessions").pick()
	end
	if not check() then
		return
	end
	local tasks = M.list()
	if #tasks == 0 then
		vim.notify("No sidekick tasks", vim.log.levels.INFO)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local previewers = require("telescope.previewers")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	for _, t in ipairs(tasks) do
		t.status = M.status(t)
	end

	local function age(t)
		if not (t.meta and t.meta.created) then
			return ""
		end
		local s = os.time() - t.meta.created
		return s < 3600 and ("%dm"):format(s / 60)
			or s < 86400 and ("%dh"):format(s / 3600)
			or ("%dd"):format(s / 86400)
	end

	local picker
	local function make_finder()
		return finders.new_table({
			results = tasks,
			entry_maker = function(t)
				local display = ("%s %-9s %-8s %-4s %s"):format(
					t.hidden and "hidden" or "shown ",
					t.status,
					t.tool,
					age(t),
					t.title
				)
				return { value = t, display = display, ordinal = t.tool .. " " .. t.title .. " " .. t.status }
			end,
		})
	end

	local function selected()
		local e = action_state.get_selected_entry()
		return e and e.value
	end

	picker = pickers.new({}, {
		prompt_title = "Agent sessions  (<CR> show · <C-h> hide · <C-s> send · <C-x> kill)",
		finder = make_finder(),
		sorter = conf.generic_sorter({}),
		previewer = previewers.new_buffer_previewer({
			title = "Agent screen",
			define_preview = function(self, entry)
				local t = entry.value
				local lines = {}
				if t.meta and t.meta.prompt then
					lines = vim.split("Prompt: " .. t.meta.prompt, "\n", { plain = true })
					lines[#lines + 1] = ("─"):rep(60)
				end
				vim.list_extend(lines, t.panel:capture())
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				vim.schedule(function()
					local win = self.state.winid
					if win and vim.api.nvim_win_is_valid(win) then
						pcall(vim.api.nvim_win_set_cursor, win, { #lines, 0 })
					end
				end)
			end,
		}),
		attach_mappings = function(bufnr, map)
			actions.select_default:replace(function()
				local t = selected()
				actions.close(bufnr)
				if t then
					M.show(t)
				end
			end)
			map({ "i", "n" }, "<C-h>", function()
				local t = selected()
				if t then
					M.hide(t)
					t.hidden = true
					picker:refresh(make_finder(), { reset_prompt = false })
				end
			end)
			map({ "i", "n" }, "<C-x>", function()
				local t = selected()
				if t and vim.fn.confirm("Kill task '" .. t.title .. "'?", "&Yes\n&No", 2) == 1 then
					M.kill(t)
					tasks = vim.tbl_filter(function(x)
						return x.block_id ~= t.block_id
					end, tasks)
					picker:refresh(make_finder(), { reset_prompt = false })
				end
			end)
			map({ "i", "n" }, "<C-s>", function()
				local t = selected()
				actions.close(bufnr)
				if t then
					require("sidekick_ext.input").open({ title = "Send to " .. t.title }, function(text)
						M.send(t, text)
					end)
				end
			end)
			return true
		end,
	})
	picker:find()
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	vim.api.nvim_create_user_command("SkTask", function(a)
		if a.args ~= "" then
			M.submit({ prompt = a.args, show = a.bang })
		else
			M.prompt({ show = a.bang })
		end
	end, { nargs = "*", bang = true, desc = "Start a hidden sidekick task (! = visible)" })
	vim.api.nvim_create_user_command("SkTasks", M.pick, { desc = "Pick a sidekick task" })
end

return M
