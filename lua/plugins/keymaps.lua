-- Moves plugin keys to the shared Zed / IdeaVim layout (see lua/config/keymaps.lua).

--- Rewrite a plugin's merged key list. `rename` maps old lhs -> new lhs or false (drop);
--- `fallback(lhs)` handles keys not in the table.
local function rekey(rename, fallback, extra)
  return function(_, keys)
    local out = {}
    for _, k in ipairs(keys or {}) do
      local lhs = type(k) == "table" and k[1] or k
      local new = rename[lhs]
      if new == nil and fallback then
        new = fallback(lhs)
      end
      if new ~= false then
        if type(new) == "string" and type(k) == "table" then
          k = vim.tbl_extend("force", {}, k)
          k[1] = new
        end
        out[#out + 1] = k
      end
    end
    return vim.list_extend(out, extra or {})
  end
end

local function prefix(from, to)
  return function(lhs)
    if type(lhs) == "string" and lhs:sub(1, #from) == from then
      return to .. lhs:sub(#from + 1)
    end
  end
end

return {
  -- Finders move from ␣f (format) to ␣s; ␣e explorer; ␣␣ open buffers (Zed tab switcher).
  {
    "folke/snacks.nvim",
    keys = rekey({
      ["<leader>ff"] = "<leader>sf",
      ["<leader>fF"] = "<leader>sF",
      ["<leader>fr"] = "<leader>s.",
      ["<leader>fe"] = "<leader>e",
      ["<leader>fE"] = "<leader>E",
      ["<leader>e"] = false, -- LazyVim's remaps to ␣fe / ␣fE
      ["<leader>E"] = false,
      ["<leader><space>"] = false,
    }, function(lhs)
      if type(lhs) == "string" and lhs:match("^<leader>f.") then
        return false
      end
    end, {
      { "<leader><space>", function() Snacks.picker.buffers() end, desc = "Open buffers" },
      { "<leader>gm", function() Snacks.picker.git_status() end, desc = "Git status" },
    }),
  },

  -- ␣q closes the buffer; sessions move to ␣Q.
  { "folke/persistence.nvim", keys = rekey({}, prefix("<leader>q", "<leader>Q")) },

  -- ␣t is the terminal; tests move to ␣T.
  { "nvim-neotest/neotest", keys = rekey({}, prefix("<leader>t", "<leader>T")) },

  -- Zed / IntelliJ: do = step over, dO = step out (LazyVim has them the other way round).
  {
    "mfussenegger/nvim-dap",
    keys = rekey({
      ["<leader>do"] = "<leader>dO",
      ["<leader>dO"] = "<leader>do",
      ["<leader>td"] = "<leader>Td", -- test.core's "Debug Nearest" lives on this spec
    }),
  },

  -- ␣a matches Zed: ac toggle, aj sessions, as send selection / this; NES on Option+Tab.
  {
    "folke/sidekick.nvim",
    keys = rekey({
      ["<tab>"] = false,
      ["<leader>aa"] = "<leader>ac",
      ["<leader>as"] = "<leader>aj",
      ["<leader>at"] = "<leader>as",
      ["<leader>av"] = false, -- ␣as covers visual mode
    }, nil, {
      {
        "<M-Tab>",
        function()
          LazyVim.cmp.map({ "ai_nes" })()
        end,
        mode = { "n" },
        desc = "Next edit suggestion",
      },
      {
        "<M-Tab>",
        function()
          if LazyVim.cmp.map({ "ai_nes", "ai_accept" })() then
            vim.cmd("let &undolevels = &undolevels")
          end
        end,
        mode = { "i" },
        desc = "Accept inline suggestion",
      },
    }),
  },

  -- Inline suggestions & NES on Option+Tab; Tab stays for snippets / indentation.
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        list = {
          selection = { auto_insert = false },
        },
      },
      keymap = {
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<M-Tab>"] = {
          function(cmp)
            if LazyVim.cmp.map({ "ai_nes", "ai_accept" })() then
              vim.cmd("let &undolevels = &undolevels")
              cmp.hide()
            end
            return true
          end,
        },
      },
    },
  },

  -- Hunks on ␣h (LazyVim: ␣gh).
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(buf)
        local gs = package.loaded.gitsigns
        local function m(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
        end
        m("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next hunk")
        m("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev hunk")
        m("n", "]H", function() gs.nav_hunk("last") end, "Last hunk")
        m("n", "[H", function() gs.nav_hunk("first") end, "First hunk")
        m({ "n", "x" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage / unstage hunk")
        m({ "n", "x" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
        m("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
        m("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
        m("n", "<leader>hp", gs.preview_hunk_inline, "Preview hunk inline")
        m("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        m("n", "<leader>hB", function() gs.blame() end, "Blame buffer")
        m("n", "<leader>hd", gs.diffthis, "Diff this")
        m({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
      end,
    },
  },

  -- ␣ss workspace symbols and ␣o outline, as in Zed / IdeaVim.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "<leader>sS", false },
            {
              "<leader>ss",
              function() Snacks.picker.lsp_workspace_symbols({ filter = LazyVim.config.kind_filter }) end,
              desc = "Workspace symbols",
              has = "workspace/symbol",
            },
            {
              "<leader>o",
              function() Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter }) end,
              desc = "Outline (document symbols)",
              has = "documentSymbol",
            },
          },
        },
      },
    },
  },

  -- which-key groups for the layout above.
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      local drop = { ["<leader>f"] = true, ["<leader>q"] = true, ["<leader>w"] = true, ["<leader>gh"] = true }
      local function filter(spec)
        for i = #spec, 1, -1 do
          local s = spec[i]
          if type(s) == "table" then
            if drop[s[1]] and (s.group or s.proxy) then
              table.remove(spec, i)
            else
              filter(s)
            end
          end
        end
      end
      filter(opts.spec or {})
      table.insert(opts.spec, {
        mode = { "n", "x" },
        { "<leader>a", group = "ai" },
        { "<leader>h", group = "hunks" },
        { "<leader>r", group = "refactor" },
        { "<leader>t", group = "terminal" },
        { "<leader>T", group = "test" },
        { "<leader>v", group = "splits" },
        { "<leader>z", group = "folds" },
        { "<leader>Q", group = "quit/session" },
      })
    end,
  },
}
