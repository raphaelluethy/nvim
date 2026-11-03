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
nvim-lspconfig, nvim-tree, oil, sidekick, and telescope. The rest track their
default branch because their tags are stale or missing, or because the release
lacks something this config needs (mason-lspconfig's `tsc` mapping;
trouble.nvim's Neovim 0.12 decoration-provider fix). nvim-treesitter must stay
on `main`. blink.cmp stays on the latest 1.x release (`version = "1.*"`).
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

Folds come from tree-sitter (`foldexpr`), open by default (`foldlevel=99`).
Diagnostics show inline text on the cursor line only; `gh` opens the float.

## Markdown

`lua/plugins/markvim.lua` loads the local markvim plugin
(`~/Documents/projects/private/markvim`) for markdown files and LSP hover
floats. Files open in live mode (only the cursor line is raw); `<leader>tm`
toggles rendering and `<leader>tM` cycles live, preview and split mode.
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
`lua/config/appearance.lua` follows the system setting: on macOS it reads the
system appearance once the UI is up and when Neovim regains focus. Terminals that
send theme notifications (Ghostty, kitty, WezTerm) switch it live.

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

## AI

- **99** is disabled; its Cursor SDK configuration and `<leader>9…` mappings
  are retained in `lua/plugins/99.lua` for re-enabling later.
- **GitHub Copilot** provides AI completion through `copilot-language-server`
  (installed by Mason). Sign in once with `:LspCopilotSignIn`.
  - Ghost text uses Neovim's native `vim.lsp.inline_completion`: `<Tab>`
    accepts, `<M-]>` / `<M-[>` cycle alternatives.
  - [Sidekick](https://github.com/folke/sidekick.nvim) shows Copilot next edit
    suggestions as inline diffs after you pause or leave insert mode. `<Tab>`
    jumps to the suggested edit, then applies it.
  - `<leader>ta` toggles both.
- **[Sidekick](https://github.com/folke/sidekick.nvim)** replaces CodeCompanion
  for native AI CLI sessions and editor context.

Sidekick loads at startup for next edit suggestions. It uses the existing
Telescope integration and native Neovim terminals, without requiring a terminal
multiplexer. Each CLI must be installed and authenticated separately.
Cursor uses the local `agent` command; Factory Droid uses `droid`.

| Key | Action |
| --- | --- |
| `<leader>cc` | Toggle CLI; choose an installed tool if none is attached |
| `<leader>cn` | Choose an agent, then submit a task and open its terminal (`<C-s>`) |
| `<leader>jn` | Submit a task in the background |
| `<leader>jj` | List background tasks and open their terminals |
| `<leader>cl` | Select an installed CLI, including Codex |
| `<leader>cA` | Select a prompt |
| `<leader>ci` | Send cursor context |
| `<leader>cs` (visual) | Send file, selection position, and fenced selection |
| `<leader>cF` | Send current file reference |
| `<leader>cd` | Send diagnostics: in Trouble the item / group under the cursor or the selection, elsewhere the open Trouble view, else all diagnostics (`:SkDiagnostics[!] [all]`) |
| `<leader>cD` | Send every diagnostic in the open Trouble view |
| `<leader>cN` | Start an agent session in a floating window |
| `<leader>cj` | Manage interactive agent sessions |
| `<leader>c]` / `<leader>c[` | Next / previous session |
| `<leader>cw` | Switch the active session between split and float |
| `<leader>ch` | Hide interactive agent sessions |
| `<leader>cx` | Kill the active interactive session (with confirmation) |

Context is inserted into the CLI input for review, not automatically submitted.

### Droid IDE connection (no hook required)

Droid sessions launched through the agent mappings connect directly to Neovim.
The local `sidekick_ext.droid_ide` bridge shares the last active file, cursor,
visual selection, loaded files, unsaved-change flags, and diagnostics through
Droid's IDE MCP protocol. Focus can stay in the agent terminal without losing
the source-file context. File contents are not automatically saved.

- Start a **new** Droid session after restarting Neovim. Use `/ide` in Droid
  to inspect or disconnect the connection.
- For a manually opened Neovim terminal, run `:DroidIDE start` **before**
  launching `droid`. `:DroidIDE stop` closes the bridge.
- No `UserPromptSubmit` hook is needed for Droid. If you previously configured
  `bin/agent-editor-context` as a Droid hook, remove that specific hook through
  Droid's `/hooks` manager to avoid duplicate context. Other agents can keep it.

The bridge uses a loopback-only HTTP server, rejects browser origins, requires
a random session ID after initialization, and removes its discovery lock on
exit. It starts on demand, not at editor startup. It needs no extra runtime.

This is an unofficial adapter for an undocumented Droid protocol. Droid may
label an automatically connected session **VS Code**, even though Neovim is the
server. Its disconnected `/ide` install/reconnect flow still checks for the
official VS Code extension; start a new Droid session instead. External
terminals may discover Neovim with Droid's `ideAutoConnect` setting, but this
is not enabled by this configuration. Native diff approvals and waiting for
an edited file to be saved are not implemented; normal terminal behavior remains.
The bridge advertises only a file-opening tool, which opens a separate tab.

Run the bridge tests with `nvim --headless -u NONE -l tests/droid_ide.lua`
(requires Python 3).

### Review panel

`<leader>mr` opens the [codediff](https://github.com/esmuellert/codediff.nvim)
review panel. From a file buffer it preselects that file and keeps your line.
`<leader>mg` opens [magirev-nvim](https://github.com/raphaelluethy/magirev-nvim),
a standalone full-width review tab, independent of codediff and Sidekick.
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

`m` moves a selection into a named group; `e` renames it. `G` or `<leader>mG`
requests AI grouping through opencode, with confirmation before sending code.
Manual grouping works offline. `r` refreshes, `?` shows help, and `q` closes.
The local development checkout is `~/Documents/projects/private/magirev-nvim`; configure its provider
in `lua/plugins/magirev.lua`. Existing codediff review-comment mappings remain.

The task form offers model and effort selectors after choosing the agent.
Set `backend = "buffer"` (default) or `backend = "rex"` in the
`sidekick_ext.tasks.setup` call in `lua/plugins/sidekick.lua` to choose where tasks run.
`<leader>cn` opens the task terminal; `<leader>jn` starts it hidden.
Use `<leader>jj` to open tasks in the selected destination later.
Buffer tasks run until Neovim closes. Rex tasks survive Neovim closing while the
Rex session stays alive.
Save buffers before asking a CLI to read files. In the CLI terminal, `<C-q>`
leaves terminal mode and `q` in normal mode hides the window without stopping
the session. Existing `<leader>cf` formatting and `<leader>a` Harpoon mappings
are unchanged.
