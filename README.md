# Neovim Configuration

Custom configuration using [lazy.nvim](https://github.com/folke/lazy.nvim),
not the LazyVim distribution. Requires Neovim 0.12+ and Git.

## Plugins

`lua/config/lazy.lua` bootstraps lazy.nvim and imports `lua/plugins/`.
`lazy-lock.json` is the only plugin lockfile.

- `:Lazy` opens the plugin manager.
- `:Lazy install` installs missing plugins without updating existing ones.
- `:Lazy check` checks for plugin updates; `:Lazy update` applies them and updates
  `lazy-lock.json`.
- `:Lazy restore` restores plugin revisions from the lockfile.
- `:TSUpdate` updates installed Treesitter parsers. Requires the `tree-sitter`
  CLI >= 0.26.1 (`brew install tree-sitter-cli` on macOS).
- `:Mason` manages language servers, formatters, and debug adapters.

Plugins with maintained semver releases follow the latest release
(`version = "*"`): gitsigns, mason, mason-nvim-dap, mini.icons,
nvim-lspconfig, oil, and snacks.nvim. FFF is pinned
to a release tag to avoid its commit-named build tags. The rest track their
default branch because their tags are stale or missing, or because the release
lacks something this config needs (mason-lspconfig's `tsc` mapping;
trouble.nvim's Neovim 0.12 decoration-provider fix). nvim-treesitter must stay
on `main`. blink.cmp stays on the latest 1.x release (`version = "1.*"`),
and indent-blankline.nvim stays on 3.x (`version = "3.*"`).
Exact installed revisions are pinned in `lazy-lock.json`.

On macOS, update Neovim with `brew update` followed by `brew upgrade neovim`.
Restart Neovim after updating it or its plugins.

## Language servers

`lua/config/servers.lua` lists the language servers and tools. Mason
(`lua/plugins/mason.lua`, loaded after startup) installs them;
`lua/plugins/lsp.lua` enables exactly that list with `vim.lsp.enable()`, so
servers Mason happens to have installed but that are not listed stay off.
Per-server settings live in `lua/plugins/lsp.lua`; per-project overrides go
in a `.nvim.lua` next to the project (`'exrc'`, confirmed once with `:trust`),
e.g. `vim.lsp.config("gopls", { settings = { ... } })`.

`<leader>w` saves in normal mode. `<leader>f` (also `<leader>cf`) formats the
buffer in normal mode or just the selection in characterwise/linewise Visual
mode. `<C-s>` saves and `<A-f>` formats in normal, insert, visual and select
mode. Saving also formats (conform's `format_after_save`). Workspace symbols
are `<leader>ss`; insert-mode signature help comes from blink.cmp.

### Completion

blink.cmp shows LSP, path, snippet and buffer items in its menu (`<leader>uc`
toggles it). Copilot suggestions appear only as inline ghost text. `<leader>ua`
starts or stops the Copilot server itself without affecting the completion
menu or other LSP servers. Both start enabled; the toggles apply only to the
current Neovim session. Telemetry is off and next edit suggestions are not
enabled. Sign in once with `:LspCopilotSignIn`.

`<leader>ue` toggles how you accept Copilot suggestions for the current session:

- **Eager (default):** Tab accepts Copilot ghost text when it isn't jumping
  through a snippet. Without a suggestion, Tab behaves normally. Option+Tab
  only accepts menu items.
- **Lazy:** Option+Tab accepts the selected menu item, then Copilot ghost
  text if nothing is selected, then the first menu item.

Ghost text appears in both modes, and Copilot acceptance works even with the
Blink menu off. Enter inserts a newline. The terminal must forward Option+Tab
as Meta+Tab (`<M-Tab>`, aka `<A-Tab>`).

Folds come from tree-sitter (`foldexpr`), open by default (`foldlevel=99`).
Diagnostics show inline text on the cursor line only; `gh` opens the float.

### Leader groups

Press `<leader>` and wait for which-key (`<leader>?` shows buffer-local maps).

| Prefix | Group |
| --- | --- |
| `<leader>c` | Code: `ca` action, `cf` format, `cr` rename |
| `<leader>d` | Debug (also `<F5>`, `<F10>`–`<F12>`) |
| `<leader>g` | Git: `gg` Neogit, `gd` codediff, `gm` Magirev |
| `<leader>h` | Hunks (`hp` `hs` `hr` `hb`) and `ha` Harpoon add; `<leader>e` Harpoon menu |
| `<leader>m` | Review comments: `ma` add, `md` delete, `ml` list, `my` copy, `mc` clear; `<leader>M` merge conflicts (codediff) |
| `<leader>s` | Search: FFF files (`sf`) and grep (`sg`, `sG`, `sw`); Snacks symbols (`ss`) and other pickers |
| `<leader>t` | Terminals: `tt` toggle (`<A-t>`), `tv` `ts` `tf` `tT` |
| `<leader>u` | UI toggles: `uu` Undotree, `uh` inlay hints, `ui` indent guides, `uc` completion menu, `ua` Copilot server, `ue` eager/lazy Copilot, `um`/`uM` markdown |
| `<leader>v` | Splits |
| `<leader>x` | Diagnostics & lists: `xx` Trouble, `xq` quickfix, `xl` loclist |

### Pickers

FFF indexes the current directory on first use. Use `:FFFResume` to resume a
file or grep search and `:FFFHealth` to check its native binary and setup.

Snacks (`snacks.picker`) handles the other pickers, Neogit selections, and
`vim.ui.select`, with live syntax-highlighted previews. `<leader>sb` lists
Snacks pickers and `<leader>sr` resumes the last one. `<leader>/` fuzzy-finds
lines in the current buffer; `<leader>s/` greps across open buffers.

Snacks displays LSP results for `gr`, `gI`, `gt`, `<leader>o` (document
symbols), and `<leader>ss` (live workspace symbols). `gd` uses native
navigation: it jumps to a single definition and puts multiple results in
quickfix.

## Markdown

`lua/plugins/markvim.lua` loads the local markvim plugin
(`~/Documents/projects/private/markvim`) for markdown files and LSP hover
floats. Files open in live mode (only the cursor line is raw); `<leader>um`
toggles rendering and `<leader>uM` cycles live, preview and split mode.
Diagrams need a backend: `:Markvim install node` for mermaid/pele,
`:checkhealth markvim` lists what is available.

## Appearance

The colorscheme is `monokai-pro-zed` from the private
`raphaelluethy/monokai-pro-zed` repo (the zed-mp themes; they are licensed,
so they are not part of this config). lazy.nvim clones it over SSH; without
access, Neovim keeps its default colorscheme. It follows `'background'`:
Monokai Pro (Filter Spectrum) V3 when dark, Monokai Pro Light (Filter Sun) V3
when light; change them in `lua/plugins/monokai-pro-zed.lua`. Every variant is
also its own `:colorscheme`, e.g. `monokai-pro-filter-spectrum-v3-no-italics`
(V3 draws inlay hints like Zed; No Italics drops every italic).
`lua/config/appearance.lua` always starts dark, ignoring the system and
terminal appearance; `:ThemeToggle` (or `:themetoggle`) switches between dark
and light.

Indent guides are on by default, highlighting the active scope in
files with a Treesitter parser. Use `<leader>ui` or `:IBLToggle` to toggle the guides.

## Debugging

`lua/plugins/dap.lua` loads nvim-dap on a debugger command or keypress.
Mason installs debugpy (Python), Delve (Go), and CodeLLDB (C/C++/Rust)
when DAP first loads. Wait for installation to finish before starting a session.
Python debugging detects project virtual environments, including `.venv`.
Native-code debugging prompts for a compiled executable; build it with debug
symbols first. Go debugging requires the Go toolchain.

| Key | Action |
| --- | --- |
| `<F5>` / `<leader>dc` | Start / continue |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<F10>` / `<leader>do` | Step over |
| `<F11>` / `<leader>di` | Step into |
| `<F12>` / `<leader>dO` | Step out |
| `<leader>dl` | Run last configuration |
| `<leader>dt` | Terminate |
| `<leader>du` | Toggle debugger UI |
| `<leader>de` | Evaluate word / visual selection |
| `<leader>dr` | Toggle debugger REPL |

The debugger UI opens when a session initializes and closes on exit,
termination, or disconnect. It includes scopes, stack frames, watches,
breakpoints, a REPL, and console.

Project-specific configurations in `.vscode/launch.json` are loaded
automatically when starting with `<F5>` / `<leader>dc`. Use standard JSON;
comments and trailing commas are not enabled. Adapter types are `python`,
`delve`, and `codelldb`. Other languages need their own adapters and launch
configurations.

Java and Kotlin debug through intellij-lsp.nvim on the same keys. In those
buffers `<F5>` / `<leader>dc` with no session running debugs the class at the
cursor, `<leader>de` evaluates through IntelliJ, and a few keys are added:

| Key | Action |
| --- | --- |
| `<leader>dd` | Debug the class at the cursor |
| `<leader>dw` | Watch word / visual selection |
| `<leader>dv` | IntelliJ debug panel (stack, locals, watches) |

## Review panel

`<leader>gd` opens the [codediff](https://github.com/esmuellert/codediff.nvim)
review panel; from a file buffer it preselects that file and keeps your line.
`<leader>gm` opens [magirev-nvim](https://github.com/raphaelluethy/magirev-nvim),
a standalone full-width review tab, independent of codediff.
`Tab` expands inline diffs, `]g`/`[g` move between groups, and `]h`/`[h` between
hunks. `s` stages the selected group or hunk; `u` unstages it. `c` opens a commit
message editor showing **all staged changes**, with `Ctrl-c Ctrl-c` to confirm
the commit and `Ctrl-c Ctrl-k` to cancel. To commit groups separately, stage
one group, commit, then repeat.

Inline diffs highlight changed words. `v` opens a unified file diff; `V` opens
a side-by-side split. Inside a diff, `v` switches layouts and `q` returns.
`gd` or `o` opens the real source file at the selected line, where your normal
LSP navigation applies.

`d` discards the selected **unstaged** group or entire hunk after confirmation.
The index is preserved; unstage with `u` first if needed. Selected untracked
files are deleted, and there is no Magirev undo.

`m` moves a selection into a named group; `e` renames it. `r` refreshes, `?` shows help, and `q` closes.
The local development checkout is `~/Documents/projects/private/magirev-nvim`.

### Review comments

`<leader>ma` comments the cursor line or the selection (also in codediff's
revision panes), `<leader>ma` again on a comment edits it. Comments persist per
repo and branch and follow the code as you edit. `<leader>my` (`:Review copy`)
copies all of them, with locations and the commented code, as Markdown to the
clipboard, ready to paste anywhere. `:Review add|edit|delete|list|copy|clear`.

## Editor context for agents

Neovim writes the current file, cursor and last visual selection to
`~/.local/state/nvim/editor-context/<pid>.json` when you leave it (focus lost,
cursor idle, buffer switch). `bin/agent-editor-context` prints the newest
snapshot of a running Neovim for the current directory, so an agent in a Rex
pane next to Neovim knows what "this" or "here" means. It is a plain file read
with no connection to Neovim; when nothing matches it prints nothing.

- Claude Code / Codex: `UserPromptSubmit` hook running
  `"$HOME/.config/nvim/bin/agent-editor-context" json`.
- Anything else: `agent-editor-context text` prints the same as plain text.
