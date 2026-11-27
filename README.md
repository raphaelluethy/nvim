# Neovim Configuration

Personal Neovim configuration built on [LazyVim](https://www.lazyvim.org/), with
keymaps aligned to a shared Zed / IdeaVim leader layout, native GitHub Copilot
inline completions + Sidekick Next Edit Suggestions (NES), `nvim-dap-view`
debugging, `oil.nvim`, and language tooling for Rust, Go, TypeScript, Python,
C/C++, Java/Kotlin, Typst, and web stacks.

## Requirements

- **Neovim >= 0.12** (native `vim.lsp.inline_completion`; Neovim nightly / 0.13+
  for native multi-cursor support on `gl` / `ga`)
- **Git** and a **Nerd Font**
- **CLI tools:** `ripgrep`, `fd`, `tree-sitter` CLI, and Node.js (for
  `copilot-language-server` and web/TS servers)
- **Terminal key forwarding:** your terminal should forward `Option+Tab` as
  `<M-Tab>` (`<A-Tab>`), `Option+[` / `Option+]` as `<M-[>` / `<M-]>`, and
  `Option+t` as `<A-t>`

## Installation

1. Back up any existing Neovim config:

   ```sh
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. Clone this repository:

   ```sh
   git clone https://github.com/raphaelluethy/nvim.git ~/.config/nvim
   ```

3. Start Neovim (`nvim`). `lazy.nvim` will bootstrap itself and install plugins
   from `lazy-lock.json`, and Mason will install configured language servers,
   formatters, and debug adapters.

4. Sign in to GitHub Copilot once (optional):

   ```vim
   :LspCopilotSignIn
   ```

### Adapting to your own machine

A few files reference private repos or local binaries and should be edited or
removed if you are setting this up yourself:

- **Colorscheme (`lua/plugins/colorscheme.lua`):** uses the private SSH repo
  `raphaelluethy/monokai-pro-zed`. Without access, switch `colorscheme` to
  `"tokyonight"` or `"catppuccin"` (both are already included by LazyVim) and
  remove the `monokai-pro-zed` spec.
- **Markdown renderer (`lua/plugins/markvim.lua`):** points to a local checkout
  at `~/Documents/projects/private/markvim`. Delete this file if you don't have
  it.
- **Go LSP (`lua/plugins/lsp.lua`):** disables `gopls` in favor of a local
  `~/.config/zed-goland/bin/zed-goland` binary. Remove the `gopls` and `goland`
  entries to use standard `gopls` from LazyVim's `lang.go` extra.
- **Java / Kotlin (`lua/plugins/intellij-lsp.lua`):** uses JetBrains'
  `intellij-lsp.nvim` (EU region, data sharing off). Remove if you don't use it.
- **Rex pane navigation (`lua/config/rex.lua`, `lua/plugins/rex.lua`):**
  crosses from Neovim splits into neighbouring Rex terminal panes on
  `<C-h/j/k/l>`. Outside Rex it falls back cleanly to normal Neovim window
  navigation, so no change is needed.

## Repository Structure

```text
init.lua                   Entry point (loads config.lazy)
lazy-lock.json             Pinned plugin revisions
lua/
  config/
    lazy.lua               lazy.nvim bootstrap and LazyVim extras list
    options.lua            Editor options and LazyVim globals (ty, tsc, ai_cmp=false)
    keymaps.lua            Core keymaps (Zed / IdeaVim layout, multicursor, folds, splits)
    autocmds.lua           :ThemeToggle command and light-theme diff contrast boost
    rex.lua                <C-h/j/k/l> navigation across Neovim windows and Rex panes
  plugins/
    colorscheme.lua        monokai-pro-zed (dark/light variants)
    dap.lua                nvim-dap + nvim-dap-view (replaces nvim-dap-ui)
    intellij-lsp.lua       JetBrains LSP & debugger for Java/Kotlin
    keymaps.lua            Plugin keymap overrides (Snacks, Blink, Sidekick, Gitsigns, LSP, which-key)
    lsp.lua                goland, web LSPs, Copilot guardrails, Java/Kotlin Treesitter & Conform
    markvim.lua            Local Markdown renderer (live/preview/split modes)
    neotest.lua            neotest-vitest adapter
    oil.lua                oil.nvim as default directory explorer (-)
    rex.lua                Rex navigation inside Snacks terminals
    sidekick.lua           Sidekick AI CLI tool list and Agent Panel toggle
    snacks.lua             Snacks overrides (smooth scrolling disabled)
    ui.lua                 Noice LSP doc borders and mini progress height cap
```

## Included LazyVim Extras & Tooling

Configured in `lua/config/lazy.lua`:

- **AI:** `ai.copilot-native`, `ai.sidekick`
- **Debugging & Testing:** `dap.core`, `test.core` (plus `neotest-vitest`)
- **Languages:**
  - Rust (`lang.rust` / `rustaceanvim`)
  - Go (`lang.go`, overridden to `goland` in `lua/plugins/lsp.lua`)
  - TypeScript / JavaScript (`lang.typescript` with `tsc`, `lang.typescript.oxc`)
  - Python (`lang.python` with `ty`)
  - C / C++ (`lang.clangd`)
  - Java / Kotlin (`intellij-lsp.nvim`, `google-java-format` AOSP style, `ktfmt`)
  - Web & docs (`lang.tailwind`, `lang.json`, `lang.typst`, `cssls`, `html`, `emmet_language_server`)

Project-local overrides are supported via `'exrc'` (`.nvim.lua` in a project
root, confirmed once with `:trust`).

## Completions & AI

### Regular completions (`blink.cmp`)

- Provides LSP, path, snippet, and buffer completions in the popup menu.
- `vim.g.ai_cmp = false` disables Blink's own ghost text so it never overlaps
  Copilot's inline suggestions.
- `auto_insert = false` keeps `<C-n>`/`<C-p>` menu browsing from mutating the
  buffer; `<CR>` or `<C-y>` accepts the selected item.
- `<Tab>` jumps forward through snippets or indents normally.

### GitHub Copilot & Sidekick NES

- **Insert mode (inline ghost text):** powered by Neovim's native
  `vim.lsp.inline_completion` via `copilot-language-server`. Copilot never
  appears in Blink's menu, skips unnamed/special buffers and secrets
  (`.env*`, `*.pem`, `*.key`), and has telemetry disabled.
- **Normal mode (Next Edit Suggestions):** `sidekick.nvim` predicts follow-up
  edits across the file after you leave Insert mode or make a Normal-mode edit,
  rendering them as inline diffs + gutter signs.
- **Accepting & cycling:**
  - `<M-Tab>` in Insert mode accepts Copilot ghost text (with an undo break so
    `<Esc>u` reverts only the accepted completion) and hides the Blink menu.
  - `<M-Tab>` in Normal mode jumps to the next Sidekick NES edit, then applies
    it on the second press and chains to the next suggestion.
  - `<M-]>` / `<M-[>` cycle through alternative Copilot inline suggestions.
  - `<Esc>` dismisses active NES suggestions; `<leader>uN` toggles NES.

### Sidekick AI CLIs

`lua/plugins/sidekick.lua` restricts Sidekick's CLI launcher to:
`claude`, `codex`, `copilot`, `pi`, `agy`, and `devin`.

## Keybindings

Leader is `<Space>`. Press `<Space>` and pause to inspect all groups via
`which-key` (`<leader>?` shows buffer-local maps).

### Leader groups

| Prefix | Group |
| --- | --- |
| `<leader><space>` | Open buffers (Snacks picker) |
| `<leader>a` | AI (Sidekick CLIs & Agent Panel) |
| `<leader>c` | Code actions, format, LSP |
| `<leader>d` | Debug (DAP / `nvim-dap-view` / IntelliJ) |
| `<leader>e` / `<leader>E` | File explorer (Snacks) |
| `<leader>f` | Format buffer or visual selection |
| `<leader>g` | Git (`<leader>gm` git status) |
| `<leader>h` | Git hunks (Gitsigns) |
| `<leader>o` | Document symbols outline |
| `<leader>q` | Close buffer |
| `<leader>Q` | Sessions & quit (`<leader>Qq` quit all) |
| `<leader>r` | Refactorings (extract / inline) |
| `<leader>s` | Search & finders (`sf` files, `sg` grep, `ss` workspace symbols, `s.` recent) |
| `<leader>t` | Terminals |
| `<leader>T` | Tests (Neotest) |
| `<leader>u` | UI toggles (`uN` NES, `um`/`uM` Markdown, `un` dismiss notifications, etc.) |
| `<leader>v` | Splits |
| `<leader>w` | Save buffer |
| `<leader>x` | Diagnostics & Trouble |
| `<leader>z` | Folds (`zc` fold all, `zo` unfold all) |

### Navigation, editing & code

| Key | Mode | Action |
| --- | --- | --- |
| `<C-h/j/k/l>` | `n`, `t` | Move focus across Neovim splits and Rex panes |
| `-` | `n` | Open parent directory in `oil.nvim` |
| `gw` | `n`, `x` | Jump to word (`flash.nvim`) |
| `v` / `V` | `x` | Expand / shrink syntax selection |
| `J` / `K` | `x` | Move selected lines down / up |
| `gl` | `n`, `x` | Add multi-cursor and jump to next match |
| `ga` | `n`, `x` | Put a multi-cursor on every match in buffer |
| `<Esc>` | `n` | Clear search highlight, multi-cursors, and snippet session |
| `gh` | `n` | Open line diagnostics float |
| `g.` / `<leader>ca` | `n`, `x` | Code action |
| `cd` | `n` | Rename symbol |
| `<leader>rr` | `n`, `x` | Refactor menu |
| `<leader>rm` / `rv` / `rf` | `n`, `x` | Extract method / variable / field |
| `<leader>ri` | `n` | Inline symbol |
| `<leader>o` | `n` | Document symbols outline |
| `<leader>ss` | `n` | Workspace symbols |

### Splits & terminals

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>vv` / `vl` | `n` | Vertical split right / left |
| `<leader>vs` / `vu` | `n` | Horizontal split down / up |
| `<leader>vc` / `vo` | `n` | Close split / close other splits |
| `<A-t>` / `<leader>tt` | `n`, `t` | Toggle terminal |
| `<leader>tf` / `tT` | `n` | New floating / split terminal |

### AI & completions

| Key | Mode | Action |
| --- | --- | --- |
| `<M-Tab>` | `i` | Accept Copilot inline completion (or NES) |
| `<M-Tab>` | `n` | Jump to / apply Sidekick Next Edit Suggestion |
| `<M-]>` / `<M-[>` | `i`, `n` | Next / previous Copilot inline suggestion |
| `<leader>ab` | `n` | Toggle Sidekick Agent Panel |
| `<leader>ac` | `n` | Toggle Sidekick CLI |
| `<leader>aj` | `n` | Select Sidekick CLI session |
| `<leader>as` | `n`, `x` | Send context / selection to Sidekick |
| `<leader>af` | `n` | Send current file to Sidekick |
| `<leader>ap` | `n`, `x` | Select Sidekick prompt |
| `<leader>ad` | `n` | Detach Sidekick CLI session |
| `<C-.>` | `n`, `i`, `x`, `t` | Focus Sidekick |
| `<leader>uN` | `n` | Toggle Sidekick NES |

### Git hunks

| Key | Mode | Action |
| --- | --- | --- |
| `]h` / `[h` | `n` | Next / previous hunk |
| `]H` / `[H` | `n` | Last / first hunk |
| `<leader>hs` / `hr` | `n`, `x` | Stage / reset hunk |
| `<leader>hS` / `hR` | `n` | Stage / reset buffer |
| `<leader>hp` | `n` | Preview hunk inline |
| `<leader>hb` / `hB` | `n` | Blame line / buffer |
| `<leader>hd` | `n` | Diff this |
| `ih` | `o`, `x` | Select hunk text object |

### Debugging

| Key | Mode | Action |
| --- | --- | --- |
| `<F5>` / `<leader>dc` | `n` | Start / continue (debugs class at cursor in Java/Kotlin) |
| `<F10>` / `<leader>do` | `n` | Step over |
| `<F11>` / `<leader>di` | `n` | Step into |
| `<F12>` / `<leader>dO` | `n` | Step out |
| `<leader>db` / `dB` | `n` | Toggle / conditional breakpoint |
| `<leader>du` | `n` | Toggle `nvim-dap-view` |
| `<leader>de` | `n`, `x` | Evaluate / hover expression |
| `<leader>dW` | `n`, `x` | Add watch expression (`<leader>dw` in IntelliJ) |
| `<leader>dd` / `dv` | `n` | Debug class at cursor / open panel (Java/Kotlin) |

## Appearance & Maintenance

- Starts in dark mode with rounded window borders (`winborder = "rounded"`),
  `colorcolumn = "120"`, `scrolloff = 10`, and smooth scrolling disabled.
- `:ThemeToggle` (or `:themetoggle`) switches between dark and light variants;
  light mode automatically boosts diff and Gitsigns background contrast.
- `:Lazy` manages plugins (`:Lazy update`, `:Lazy restore`), `:Mason` manages
  LSPs/formatters/DAPs, and `:TSUpdate` updates Treesitter parsers.
