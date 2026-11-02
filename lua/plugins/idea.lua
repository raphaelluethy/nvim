-- Java and Kotlin through JetBrains' IntelliJ language server. Sign in with
-- `:Idea login`; run, test and debug through code actions and the Run and
-- Debug lenses on main methods.
return {
	dir = "~/Documents/projects/private/idea-nvim",
	name = "idea-nvim",
	ft = { "java", "kotlin" },
	cmd = "Idea",
	dependencies = { "mfussenegger/nvim-dap" },
	opts = {
		settings = {
			region = "europe",
			dataSharing = "none",
		},
	},
}
