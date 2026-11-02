-- Markdown rendering for files and LSP hover floats (local plugin). Live mode
-- shows only the cursor line raw; `<leader>tm` toggles rendering, `<leader>tM`
-- cycles live -> preview -> split. Diagrams (mermaid/pele/plantuml/d2) render
-- asynchronously once a backend is installed: `:Markvim install node`,
-- `:checkhealth markvim`.
return {
	dir = "~/Documents/projects/private/markvim",
	name = "markvim",
	ft = "markdown",
	cmd = "Markvim",
	opts = {
		mode = "live",
		float_mode = "preview",
		on_attach = function(buf)
			-- Floats (hover) get no mappings.
			if vim.b[buf].markvim_mode or vim.bo[buf].buftype ~= "" then
				return
			end
			local map = function(lhs, rhs, desc)
				vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
			end
			map("<leader>tm", function()
				require("markvim").toggle(buf)
			end, "Toggle markdown rendering")
			map("<leader>tM", function()
				local next = { live = "preview", preview = "split", split = "live" }
				local mode = next[require("markvim").mode(buf) or "live"]
				require("markvim").set_mode(mode, buf)
				vim.notify("markvim: " .. mode, vim.log.levels.INFO)
			end, "Cycle markdown mode (live/preview/split)")
		end,
	},
}
