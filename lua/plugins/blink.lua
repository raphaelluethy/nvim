return {
	"BlinkResearchLabs/blink-edit.nvim",
	config = function()
		require("blink-edit").setup({
			llm = {
				provider = "sweep",
				backend = "openai",
				url = "http://localhost:1234",
				model = "sweep-next-edit-0.5b",
			},
		})
	end,
}
