-- Java and Kotlin through JetBrains' IntelliJ language server. The helper in
-- `cli/` is built by `build`; sign in with `:Idea login`.
return {
	dir = "~/Documents/projects/private/idea-nvim",
	name = "idea-nvim",
	ft = { "java", "kotlin" },
	cmd = "Idea",
	build = "cargo build --locked --release --manifest-path cli/Cargo.toml",
	dependencies = { "mfussenegger/nvim-dap" },
	keys = {
		{ "<leader>jr", function() require("idea").run() end, desc = "IntelliJ: run main" },
		{ "<leader>jt", function() require("idea").test() end, desc = "IntelliJ: run test at cursor" },
		{ "<leader>jT", function() require("idea").test("file") end, desc = "IntelliJ: run tests in file" },
		{ "<leader>jb", function() require("idea").build() end, desc = "IntelliJ: build module" },
		{ "<leader>jd", function() require("idea").debug() end, desc = "IntelliJ: debug main" },
		{ "<leader>jD", function() require("idea").debug({ test = true }) end, desc = "IntelliJ: debug test" },
	},
	opts = {
		settings = {
			region = "europe",
			dataSharing = "none",
		},
	},
}
