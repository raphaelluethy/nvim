-- Hidden sidekick tasks: run an AI CLI in a minimized Rex floating layer and
-- bring it back later from a picker. Rex is the source of truth (layers whose
-- block label starts with "sk-task:"), so tasks survive Neovim restarts.
local Rex = require("sidekick_ext.rex")

local M = {}

local PREFIX = "sk-task:"

local Agents = require("sidekick_ext.agents")

M.config = {
	bounds = { 0.04, 0.04, 0.92, 0.92 }, -- [x, y, w, h] fractions of the Rex window
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
---@field layer_id string
---@field block_id string
---@field label string
---@field tool string
---@field title string
---@field hidden boolean
---@field meta? sidekick_ext.TaskMeta

--- All live tasks in this Rex session, oldest first.
---@return sidekick_ext.Task[]
function M.list()
	if not check() then
		return {}
	end
	local view, err = Rex.call("session.view")
	if not view then
		vim.notify("rex: " .. tostring(err), vim.log.levels.ERROR)
		return {}
	end
	local meta = load_meta()
	local live, ret = {}, {}
	for _, win in ipairs(view.windows or {}) do
		for _, layer in ipairs(win.layers or {}) do
			local block = layer.kind == "floating" and layer.blocks and layer.blocks[1]
			if block and block.label and vim.startswith(block.label, PREFIX) then
				local tool, title = block.label:sub(#PREFIX + 1):match("^([^:]+):(.*)$")
				live[block.block_id] = true
				ret[#ret + 1] = {
					layer_id = layer.layer_id,
					block_id = block.block_id,
					label = block.label,
					tool = tool or "?",
					title = title or block.label,
					hidden = layer.state == "minimized",
					meta = meta[block.block_id],
				}
			end
		end
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

--- Short status: exited / blocked / working / running.
---@param task sidekick_ext.Task
function M.status(task)
	local proc = Rex.block_call(task.block_id, "process")
	if proc and not proc.child then
		return proc.last_exit and ("exited " .. tostring(proc.last_exit.code or proc.last_exit.status or "")) or "exited"
	end
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
	local window_id = Rex.window_id()
	local cwd = opts.cwd or vim.fn.getcwd()
	local title = title_of(opts.prompt)
	local label = PREFIX .. tool .. ":" .. title
	local res, err = Rex.call("session.new_layer", {
		window_id = window_id,
		bounds = M.config.bounds,
		focus = opts.show == true,
		layout = {
			block = {
				flavor = "com.superlogical.terminal.shell",
				label = label,
				options = { command = Agents.cmd(tool, sel, opts.prompt), cwd = cwd, exit = { on_completion = false } },
			},
		},
	})
	if not res then
		vim.notify("rex: " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	if not opts.show then
		Rex.call("session.set_layer_state", { layer_id = res.layer_id, state = "minimized" })
	end
	local block_id = res.block_ids[1]
	Agents.set_last_tool(tool)
	local meta = load_meta()
	meta[block_id] = { tool = tool, prompt = opts.prompt, cwd = cwd, created = os.time() }
	save_meta(meta)
	vim.notify(("%s task started%s: %s"):format(tool, opts.show and "" or " (hidden)", title))
	return { layer_id = res.layer_id, block_id = block_id, label = label, tool = tool, title = title, hidden = not opts.show }
end

---@param task sidekick_ext.Task
function M.show(task)
	local _, err = Rex.call("session.set_layer_state", { layer_id = task.layer_id, state = "normal", focus = true })
	if err then
		vim.notify("rex: " .. err, vim.log.levels.ERROR)
	end
end

---@param task sidekick_ext.Task
function M.hide(task)
	Rex.call("session.set_layer_state", { layer_id = task.layer_id, state = "minimized" })
end

function M.hide_all()
	for _, t in ipairs(M.list()) do
		if not t.hidden then
			M.hide(t)
		end
	end
end

---@param task sidekick_ext.Task
function M.kill(task)
	Rex.call("session.close_layer", { layer_id = task.layer_id })
end

--- Send a follow-up message to a running task without showing it.
---@param task sidekick_ext.Task
---@param text string
function M.send(task, text)
	local ok, err = Rex.paste(task.block_id, text, true)
	if not ok then
		vim.notify("rex: " .. tostring(err), vim.log.levels.ERROR)
	end
end

--- Open the prompt editor and start an agent session in a Rex float. The
--- button bar picks agent, model, mode and effort (saved per agent); "Start"
--- and "Start hidden" choose whether the float is shown. In visual mode the
--- selection (with file/line references) is prefilled as context.
---@param opts? { tool?: string, show?: boolean } show = <C-s> starts visible
function M.prompt(opts)
	opts = opts or {}
	if not check() then
		return
	end
	local default
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		default = require("sidekick.cli").render({ msg = "{selection}" })
		vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	end
	local tool = opts.tool or Agents.last_tool()
	local sel = Agents.selection(tool)
	local function start(show)
		return function(text)
			M.new({ prompt = text, tool = tool, sel = sel, show = show })
		end
	end
	local actions = {
		{ label = "Start", run = start(true) },
		{ label = "Start hidden", run = start(false) },
	}
	if not opts.show then
		actions[1], actions[2] = actions[2], actions[1]
	end
	local handle
	handle = require("sidekick_ext.input").open({
		title = "New agent session",
		default = default,
		actions = actions,
		bar = function(win)
			return Agents.bar(tool, sel, function(t, new)
				tool, sel = t, new
				Agents.set_last_tool(t)
				Agents.set_selection(t, new)
				handle.refresh()
			end, win, function()
				-- Back to the prompt, ready to type (the picker leaves normal mode).
				vim.schedule(function()
					if vim.api.nvim_win_is_valid(handle.win) then
						vim.api.nvim_set_current_win(handle.win)
						vim.cmd("startinsert!")
					end
				end)
			end)
		end,
	})
end

--- Telescope picker over all tasks. Preview shows the agent's screen.
function M.pick()
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
		return s < 3600 and ("%dm"):format(s / 60) or s < 86400 and ("%dh"):format(s / 3600) or ("%dd"):format(s / 86400)
	end

	local picker
	local function make_finder()
		return finders.new_table({
			results = tasks,
			entry_maker = function(t)
				local display = ("%s %-9s %-8s %-4s %s"):format(t.hidden and "hidden" or "shown ", t.status, t.tool, age(t), t.title)
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
				vim.list_extend(lines, Rex.capture(t.block_id))
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
			M.new({ prompt = a.args, show = a.bang })
		else
			M.prompt({ show = a.bang })
		end
	end, { nargs = "*", bang = true, desc = "Start a hidden sidekick task (! = visible)" })
	vim.api.nvim_create_user_command("SkTasks", M.pick, { desc = "Pick a sidekick task" })
end

return M
