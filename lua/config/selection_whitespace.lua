-- Overlay markers without changing text, tab widths, or conceal settings.
local ns = vim.api.nvim_create_namespace("selection_whitespace")
local regions = {}
local selection_win

vim.api.nvim_set_decoration_provider(ns, {
	on_start = function()
		local mode = vim.fn.mode()
		if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
			return false
		end
		selection_win = vim.api.nvim_get_current_win()
		regions = vim.fn.getregionpos(vim.fn.getpos("v"), vim.fn.getpos("."), {
			type = mode,
			exclusive = vim.o.selection == "exclusive",
		})
	end,
	on_win = function(_, win)
		return win == selection_win
	end,
	on_range = function(_, _, buf, first_row, _, last_row)
		for _, region in ipairs(regions) do
			local start, finish = region[1], region[2]
			local row = start[2] - 1
			if row >= first_row and row <= last_row and start[3] > 0 then
				local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
				local trailing = line:find("%s*$")
				for col = start[3], math.min(finish[3], #line) do
					local char = line:sub(col, col)
					-- A block can start partway through a tab; its arrow is outside the selection.
					if (char == " " or char == "\t") and (col ~= start[3] or start[4] == 0) then
						local marker = char == "\t" and "▸" or (col >= trailing and "•" or "·")
						vim.api.nvim_buf_set_extmark(buf, ns, row, col - 1, {
							virt_text = { { marker, "Whitespace" } },
							virt_text_pos = "overlay",
							hl_mode = "combine",
							ephemeral = true,
						})
					end
				end
			end
		end
	end,
})
