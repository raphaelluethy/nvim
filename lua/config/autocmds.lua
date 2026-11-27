vim.api.nvim_create_user_command("ThemeToggle", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, { desc = "Toggle between dark and light theme" })

vim.cmd(
  [[cnoreabbrev <expr> themetoggle getcmdtype() == ':' && getcmdline() ==# 'themetoggle' ? 'ThemeToggle' : 'themetoggle']]
)

local light_boost = { line = 0.24, inline = 0.42 }

local function blend(fg, bg, a)
  local function ch(c, shift)
    return bit.band(bit.rshift(c, shift), 0xff)
  end
  local function mix(shift)
    return math.floor(ch(fg, shift) * a + ch(bg, shift) * (1 - a) + 0.5)
  end
  return mix(16) * 0x10000 + mix(8) * 0x100 + mix(0)
end

local function apply_light_boost()
  if vim.o.background ~= "light" then
    return
  end
  local function color(name, key)
    return vim.api.nvim_get_hl(0, { name = name, link = false })[key]
  end
  local bg = color("Normal", "bg")
  if not bg then
    return
  end
  for kind, fallback in pairs({ Add = "DiffAdd", Change = "DiffChange", Delete = "DiffDelete" }) do
    local accent = color("GitSigns" .. kind, "fg") or color(fallback, "fg")
    if accent then
      local line, inline = blend(accent, bg, light_boost.line), blend(accent, bg, light_boost.inline)
      vim.api.nvim_set_hl(0, "GitSigns" .. kind .. "Ln", { bg = line })
      vim.api.nvim_set_hl(0, "GitSigns" .. kind .. "Inline", { bg = inline })
      vim.api.nvim_set_hl(0, "GitSigns" .. kind .. "LnInline", { bg = inline })
    end
  end
  local diff_accents = {
    DiffAdd = color("GitSignsAdd", "fg") or color("Added", "fg"),
    DiffChange = color("GitSignsChange", "fg") or color("Changed", "fg"),
    DiffDelete = color("GitSignsDelete", "fg") or color("Removed", "fg"),
  }
  for group, accent in pairs(diff_accents) do
    if accent then
      vim.api.nvim_set_hl(0, group, {
        bg = blend(accent, bg, light_boost.line),
        fg = group == "DiffDelete" and accent or nil,
      })
    end
  end
  if diff_accents.DiffChange then
    vim.api.nvim_set_hl(0, "DiffText", { bg = blend(diff_accents.DiffChange, bg, light_boost.inline) })
  end
  local del = color("GitSignsDelete", "fg")
  if del then
    vim.api.nvim_set_hl(0, "GitSignsDeleteVirtLn", { fg = del, bg = blend(del, bg, light_boost.line) })
    vim.api.nvim_set_hl(0, "GitSignsDeleteVirtLnInline", { bg = blend(del, bg, light_boost.inline) })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("config_light_boost", { clear = true }),
  callback = apply_light_boost,
})
