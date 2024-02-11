-- Styled and colored underline support
vim.g.t_AU = "\27[58:5:%dm"
vim.g.t_8u = "\27[58:2:%lu:%lu:%lum"
vim.g.t_Us = "\27[4:2m"
vim.g.t_Cs = "\27[4:3m"
vim.g.t_ds = "\27[4:4m"
vim.g.t_Ds = "\27[4:5m"
vim.g.t_Ce = "\27[4:0m"

-- Strikethrough
vim.g.t_Ts = "\27[9m"
vim.g.t_Te = "\27[29m"

-- Truecolor support
vim.g.t_8f = "\27[38:2:%lu:%lu:%lum"
vim.g.t_8b = "\27[48:2:%lu:%lu:%lum"
vim.g.t_RF = "\27]10;?\7"
vim.g.t_RB = "\27]11;?\7"

-- Bracketed paste
vim.g.t_BE = "\27[?2004h"
vim.g.t_BD = "\27[?2004l"
vim.g.t_PS = "\27[200~"
vim.g.t_PE = "\27[201~"

-- Cursor control
vim.g.t_RC = "\27[?12$p"
vim.g.t_SH = "\27[%d q"
vim.g.t_RS = "\27P$q q\7\27\\"
vim.g.t_SI = "\27[5 q"
vim.g.t_SR = "\27[3 q"
vim.g.t_EI = "\27[1 q"
vim.g.t_VS = "\27[?12l"

-- Focus tracking
vim.g.t_fe = "\27[?1004h"
vim.g.t_fd = "\27[?1004l"
vim.cmd("set <FocusGained>=\27[I")
vim.cmd("set <FocusLost>=\27[O")

-- Window title
vim.g.t_ST = "\27[22;2t"
vim.g.t_RT = "\27[23;2t"

-- Disable background color erase
vim.o.termguicolors = true