-- Keymaps follow Zed (~/.config/zed/keymap.json), the source of truth for the
-- leader layout; ~/.ideavimrc mirrors it. Loaded on VeryLazy, after LazyVim's
-- own keymaps. Plugin-owned keys are remapped in lua/plugins/keymaps.lua.
require("config.rex").setup()

local map = vim.keymap.set

-- LazyVim keys under prefixes that are single keys here (␣w save, ␣f format, ␣q close).
for _, lhs in ipairs({ "<leader>wd", "<leader>wm", "<leader>fn", "<leader>ft", "<leader>fT", "<leader>qq" }) do
  pcall(vim.keymap.del, "n", lhs)
end

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map({ "n", "x" }, "<leader>f", function()
  LazyVim.format({ force = true })
end, { desc = "Format buffer/selection" })
map("n", "<leader>q", function()
  Snacks.bufdelete()
end, { desc = "Close buffer" })
map("n", "<leader>Qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- Diagnostics float (LazyVim also has it on ␣cd)
map("n", "gh", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Move selected lines
map("x", "J", ":m '>+1<cr>gv=gv", { desc = "Move lines down", silent = true })
map("x", "K", ":m '<-2<cr>gv=gv", { desc = "Move lines up", silent = true })

-- Expand / shrink selection by syntax node (Zed: v / V in visual mode)
map("x", "v", "an", { desc = "Expand selection", remap = true })
map("x", "V", "in", { desc = "Shrink selection", remap = true })

-- Jump anywhere on screen (Zed: helix jump, IdeaVim: easymotion)
map({ "n", "x" }, "gw", function()
  require("flash").jump()
end, { desc = "Jump to word" })

-- Code (global, so it works even when the LSP keymap is not attached)
map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map({ "n", "x" }, "g.", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "cd", vim.lsp.buf.rename, { desc = "Rename symbol" })

-- r: refactorings (IntelliJ names; LSP code actions filtered by kind)
local function refactor(kind)
  return function()
    vim.lsp.buf.code_action({ context = { only = { kind }, diagnostics = {} } })
  end
end
map({ "n", "x" }, "<leader>rr", refactor("refactor"), { desc = "Refactor menu" })
map({ "n", "x" }, "<leader>rm", refactor("refactor.extract.function"), { desc = "Extract method" })
map({ "n", "x" }, "<leader>rv", refactor("refactor.extract.variable"), { desc = "Extract variable" })
map({ "n", "x" }, "<leader>rf", refactor("refactor.extract.field"), { desc = "Extract field" })
map("n", "<leader>ri", refactor("refactor.inline"), { desc = "Inline" })

-- v: splits
map("n", "<leader>vv", "<cmd>vsplit<cr>", { desc = "Split right" })
map("n", "<leader>vl", "<cmd>aboveleft vsplit<cr>", { desc = "Split left" })
map("n", "<leader>vs", "<cmd>split<cr>", { desc = "Split down" })
map("n", "<leader>vu", "<cmd>aboveleft split<cr>", { desc = "Split up" })
map("n", "<leader>vc", "<cmd>close<cr>", { desc = "Close split" })
map("n", "<leader>vo", "<cmd>only<cr>", { desc = "Close other splits" })

-- t: terminal (tests live on ␣T)
local function term_toggle()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end
map("n", "<leader>tt", term_toggle, { desc = "Toggle terminal" })
map({ "n", "t" }, "<A-t>", term_toggle, { desc = "Toggle terminal" })
map("n", "<leader>tf", function()
  Snacks.terminal.open(nil, { cwd = LazyVim.root(), win = { position = "float" } })
end, { desc = "New terminal (float)" })
map("n", "<leader>tT", function()
  Snacks.terminal.open(nil, { cwd = LazyVim.root() })
end, { desc = "New terminal" })

-- Multi-cursor (native, :h multicursor), as in Zed / IdeaVim:
-- gl adds a cursor and jumps to the next match, ga puts a cursor on every match.
-- Match = word under cursor, or the selection in Visual mode. Then edit (ciw, A, …);
-- <C-l> clears the cursors.
local mc_ns = vim.api.nvim_create_namespace("nvim.multicursor")
local function mc_pattern()
  if vim.v.cascading then
    return -- replayed at an extra cursor: only the primary cursor adds cursors
  end
  local mode = vim.fn.mode()
  local pat
  if mode:match("[vV\22]") then
    local text = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
    vim.cmd("normal! \27")
    pat = "\\V" .. vim.fn.escape(table.concat(text, "\n"), "\\"):gsub("\n", "\\n")
  else
    pat = "\\V\\<" .. vim.fn.escape(vim.fn.expand("<cword>"), "\\") .. "\\>"
  end
  vim.fn.setreg("/", pat)
  vim.o.hlsearch = true
  return pat
end
local function mc_add_here()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_extmark(0, mc_ns, pos[1] - 1, pos[2], {})
end
map({ "n", "x" }, "gl", function()
  local pat = mc_pattern()
  if not pat then
    return
  end
  vim.fn.search(pat, "bc")
  mc_add_here()
  vim.fn.search(pat, "w")
end, { desc = "Add cursor, go to next match" })
map({ "n", "x" }, "ga", function()
  local pat = mc_pattern()
  if not pat then
    return
  end
  vim.fn.search(pat, "bc")
  local cur = vim.api.nvim_win_get_cursor(0)
  for _, m in ipairs(vim.fn.matchbufline("%", pat, 1, "$")) do
    if not (m.lnum == cur[1] and m.byteidx == cur[2]) then
      vim.api.nvim_buf_set_extmark(0, mc_ns, m.lnum - 1, m.byteidx, {})
    end
  end
end, { desc = "Cursor on every match" })
-- <C-l> (native clear) is window / Rex navigation here, so normal-mode <Esc> clears
-- the cursors too (besides LazyVim's hlsearch / snippet clearing).
map("n", "<Esc>", function()
  vim.api.nvim_buf_clear_namespace(0, mc_ns, 0, -1)
  vim.cmd("nohlsearch")
  LazyVim.cmp.actions.snippet_stop()
  return "<Esc>"
end, { expr = true, desc = "Clear hlsearch / multicursors" })

-- z: folds
map("n", "<leader>zc", "zM", { desc = "Fold all" })
map("n", "<leader>zo", "zR", { desc = "Unfold all" })
