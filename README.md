# Neovim Configuration

Custom configuration using [lazy.nvim](https://github.com/folke/lazy.nvim),
not the LazyVim distribution. Requires Neovim 0.12+ and Git.

## Plugins

`lua/config/lazy.lua` bootstraps lazy.nvim and imports `lua/plugins/`.
`lazy-lock.json` is the only plugin lockfile.

- `:Lazy` opens the plugin manager.
- `:Lazy install` installs missing plugins without updating existing ones.
- `:Lazy restore` restores plugin revisions from the lockfile.
- `:Mason` manages language servers, formatters, and debug adapters.

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

- **99** remains configured with the Cursor SDK provider and its existing
  `<leader>9…` mappings.
- **Supermaven** remains the inline completion provider: `<Tab>` accepts a
  suggestion, `<C-]>` clears it, and `<C-j>` accepts a word.
- **[Sidekick](https://github.com/folke/sidekick.nvim)** replaces CodeCompanion
  for native AI CLI sessions and editor context. Copilot next-edit suggestions
  and Copilot status notifications are disabled; no Copilot setup is required.

Sidekick loads on its first mapping or `:Sidekick` command. It uses the existing
Telescope integration and native Neovim terminals, without requiring a terminal
multiplexer. Each CLI must be installed and authenticated separately.
Cursor uses the local `agent` command; Factory Droid uses `droid`.

| Key | Action |
| --- | --- |
| `<leader>cc` | Toggle CLI; choose an installed tool if none is attached |
| `<leader>cl` | Select an installed CLI, including Codex |
| `<leader>cA` | Select a prompt |
| `<leader>ci` | Send cursor context |
| `<leader>cs` (visual) | Send selection |
| `<leader>cF` | Send current file reference |
| `<leader>cd` | Detach / close CLI |
| `<leader>c1` | Toggle Claude Code |
| `<leader>c2` | Toggle Cursor Agent |
| `<leader>c3` | Toggle Factory Droid |
| `<leader>c4` | Toggle OpenCode |

Context is inserted into the CLI input for review, not automatically submitted.
Save buffers before asking a CLI to read files. In the CLI terminal, `<C-q>`
leaves terminal mode and `q` in normal mode hides the window without stopping
the session. Existing `<leader>cf` formatting and `<leader>a` Harpoon mappings
are unchanged.

