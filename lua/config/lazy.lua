local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local result = vim.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		lazyrepo,
		lazypath,
	}):wait()

	if result.code ~= 0 then
		vim.notify(
			("Failed to clone lazy.nvim:\n%s"):format(result.stderr),
			vim.log.levels.ERROR
		)
		return
	end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	change_detection = {
		notify = false,
	},
	checker = {
		enabled = false,
	},
})
