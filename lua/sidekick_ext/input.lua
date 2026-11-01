-- Multiline floating input with an optional clickable button bar (winbar).
-- Only <C-s> or the Start button submits. q / <Esc> (normal mode), :q, or the
-- Cancel button close without doing anything.
local M = {}

---@class sidekick_ext.input.Opts
---@field title string|fun():string
---@field default? string
---@field ft? string
---@field bar? fun(win: integer): string winbar content (buttons), re-rendered via handle.refresh()
---@field submit_label? string
---@field actions? { label: string, run: fun(text: string) }[] extra submit buttons (the first one is <C-s>)

---@class sidekick_ext.input.Handle
---@field refresh fun()
---@field win integer
---@field buf integer

---@param opts sidekick_ext.input.Opts
---@param on_submit? fun(text:string) default action (when opts.actions is not given)
---@return sidekick_ext.input.Handle
function M.open(opts, on_submit)
	local actions = opts.actions or { { label = opts.submit_label or "Submit", run = on_submit } }
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = opts.ft or "markdown"
	vim.b[buf].completion = false -- keep blink.cmp's menu out of the prompt editor
	if opts.default and opts.default ~= "" then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.list_extend({ "", "" }, vim.split(opts.default, "\n", { plain = true })))
	end

	local function title()
		local t = type(opts.title) == "function" and opts.title() or opts.title
		return " " .. t .. " "
	end

	local width = math.min(110, math.floor(vim.o.columns * 0.75))
	local height = math.min(20, math.floor(vim.o.lines * 0.5))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = title(),
		title_pos = "center",
		footer = " <C-s> " .. actions[1].label .. " · q cancel ",
		footer_pos = "center",
	})
	vim.wo[win].wrap = true

	local done = false
	local function close()
		done = true
		vim.cmd.stopinsert()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	local function submit(action)
		action = action or actions[1]
		if done then
			return
		end
		local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
		if text == "" then
			return vim.notify("Prompt is empty", vim.log.levels.WARN)
		end
		close()
		vim.schedule(function()
			action.run(text)
		end)
	end

	local Agents = require("sidekick_ext.agents")
	local handle = { win = win, buf = buf }
	function handle.refresh()
		if not vim.api.nvim_win_is_valid(win) then
			return
		end
		local bar = opts.bar and opts.bar(win) or ""
		local buttons = {}
		for i, a in ipairs(actions) do
			buttons[#buttons + 1] = Agents.button(win, 80 + i, a.label, function()
				submit(a)
			end, i == 1 and "SidekickExtButtonAction" or nil)
		end
		buttons[#buttons + 1] = Agents.button(win, 99, "Cancel", close)
		vim.wo[win].winbar = bar .. "%=" .. table.concat(buttons, " ")
		vim.api.nvim_win_set_config(win, { title = title(), title_pos = "center" })
	end
	handle.refresh()

	local o = { buffer = buf, nowait = true }
	vim.keymap.set({ "n", "i" }, "<C-s>", function()
		submit()
	end, o)
	vim.keymap.set("n", "q", close, o)
	vim.keymap.set("n", "<Esc>", close, o)
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			done = true
		end,
	})

	vim.api.nvim_win_set_cursor(win, { 1, 0 })
	vim.cmd.startinsert()
	return handle
end

return M
