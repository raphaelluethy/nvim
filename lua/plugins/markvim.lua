-- Markdown rendering for files and LSP hover floats (local plugin). Live mode
-- shows only the cursor line raw; `<leader>um` toggles rendering, `<leader>uM`
-- cycles live -> preview -> split. Diagrams (mermaid/pele/plantuml/d2) render
-- asynchronously once a backend is installed: `:Markvim install node`,
-- `:checkhealth markvim`.
local function markdown_buffer()
	local buf = vim.api.nvim_get_current_buf()
	if vim.bo[buf].filetype == "markdown" and vim.bo[buf].buftype == "" and not vim.b[buf].markvim_mode then
		return buf
	end
end

return {
	dir = "~/Documents/projects/private/markvim",
	name = "markvim",
	ft = "markdown",
	cmd = "Markvim",
	dependencies = { "panels.nvim" },
	keys = {
		{
			"<leader>um",
			function()
				local buf = markdown_buffer()
				if buf then
					require("markvim").toggle(buf)
				end
			end,
			desc = "Markvim: toggle markdown rendering",
		},
		{
			"<leader>uM",
			function()
				local buf = markdown_buffer()
				if buf then
					local next = { live = "preview", preview = "split", split = "live" }
					local mode = next[require("markvim").mode(buf) or "live"]
					require("markvim").set_mode(mode, buf)
					vim.notify("markvim: " .. mode, vim.log.levels.INFO)
				end
			end,
			desc = "Markvim: cycle mode (live/preview/split)",
		},
	},
	opts = {
		mode = "live",
		float_mode = "preview",
	},
}
