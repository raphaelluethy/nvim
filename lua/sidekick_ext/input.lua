-- Multiline floating input. <C-s> (n/i) or :w submits, q / <Esc> in normal mode cancels.
local M = {}

---@class sidekick_ext.input.Opts
---@field title string
---@field default? string
---@field footer? string
---@field ft? string

---@param opts sidekick_ext.input.Opts
---@param on_submit fun(text:string)
function M.open(opts, on_submit)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "acwrite"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = opts.ft or "markdown"
	vim.api.nvim_buf_set_name(buf, "sidekick-input://" .. buf)
	if opts.default and opts.default ~= "" then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(opts.default, "\n", { plain = true }))
	end

	local width = math.min(100, math.floor(vim.o.columns * 0.7))
	local height = math.min(20, math.floor(vim.o.lines * 0.5))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " " .. opts.title .. " ",
		title_pos = "center",
		footer = " " .. (opts.footer or "<C-s> submit · q cancel") .. " ",
		footer_pos = "center",
	})
	vim.wo[win].wrap = true

	local done = false
	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	local function submit()
		if done then
			return
		end
		done = true
		local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
		vim.cmd.stopinsert()
		close()
		if text ~= "" then
			vim.schedule(function()
				on_submit(text)
			end)
		end
	end

	local o = { buffer = buf, nowait = true }
	vim.keymap.set({ "n", "i" }, "<C-s>", submit, o)
	vim.keymap.set("n", "q", close, o)
	vim.keymap.set("n", "<Esc>", close, o)
	vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = buf, callback = submit })

	if not opts.default or opts.default == "" then
		vim.cmd.startinsert()
	else
		-- Leave a blank line under prefilled context for the actual instruction.
		vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "", "" })
		vim.api.nvim_win_set_cursor(win, { 1, 0 })
		vim.cmd.startinsert()
	end
end

return M
