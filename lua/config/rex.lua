local M = {}

local rex_dirs = { h = "left", j = "down", k = "up", l = "right" }

local function available()
  return vim.env.REX_SESSION ~= nil and vim.env.REX_BLOCK ~= nil and vim.fn.executable("rex") == 1
end

local function registry_file()
  return vim.fn.stdpath("state") .. "/panels-rex-nav"
end

local function register(on)
  local session, block = vim.env.REX_SESSION, vim.env.REX_BLOCK
  if not (session and block) then
    return
  end
  local file = registry_file()
  local keep = {}
  if vim.uv.fs_stat(file) then
    for _, line in ipairs(vim.fn.readfile(file)) do
      local s, b = line:match("^(%S+)%s+(%S+)$")
      if s and not (s == session and b == block) then
        keep[#keep + 1] = line
      end
    end
  end
  if on then
    keep[#keep + 1] = session .. " " .. block
  end
  vim.fn.mkdir(vim.fs.dirname(file), "p")
  vim.fn.writefile(keep, file)
end

function M.navigate(dir)
  local direction = rex_dirs[dir]
  if not direction then
    return false
  end
  if vim.fn.mode() == "t" then
    vim.cmd.stopinsert()
  end
  local nr = vim.fn.winnr(dir)
  if nr ~= vim.fn.winnr() then
    vim.api.nvim_set_current_win(vim.fn.win_getid(nr))
    return true
  end
  if not available() then
    return false
  end
  vim.system({
    "rex",
    "api",
    "call",
    "-s",
    vim.env.REX_SESSION,
    "session.focus_direction",
    vim.json.encode({ direction = direction }),
  })
  return true
end

function M.setup()
  for key, dir in pairs(rex_dirs) do
    vim.keymap.set({ "n", "t" }, "<C-" .. key .. ">", function()
      M.navigate(key)
    end, { desc = "Go to " .. dir .. " window / Rex pane" })
  end

  if vim.env.REX_SESSION and vim.env.REX_BLOCK then
    local group = vim.api.nvim_create_augroup("config_rex_nav", { clear = true })
    if vim.v.vim_did_enter == 1 then
      register(true)
    else
      vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = function()
          register(true)
        end,
      })
    end
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = group,
      callback = function()
        register(false)
      end,
    })
  end
end

return M
